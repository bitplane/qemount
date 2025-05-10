#include "9p_handlers.h"
#include "9p_fid.h"
#include "9p_fs.h"
#include "9p_errors.h"
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <stdio.h>

int handle_version(Server *s, Fcall *in, Fcall *out) {
    if (s->debug) {
        fprintf(stderr, "handle_version: client version=%s msize=%u\n", 
                in->version.version, in->version.msize);
    }
    
    // Check if client version is supported
    if (!session_check_version(s->session, in->version.version)) {
        // Per spec, return "unknown" for unsupported versions
        strncpy(out->version.version, "unknown", sizeof(out->version.version) - 1);
        out->version.version[sizeof(out->version.version) - 1] = '\0';
        out->version.msize = s->msize;
        return 0;
    }
    
    // Negotiate message size
    out->version.msize = in->version.msize;
    if (out->version.msize > s->msize) {
        out->version.msize = s->msize;
    }
    
    // Set negotiated values in session
    session_set_msize(s->session, out->version.msize);
    session_set_version(s->session, in->version.version);
    
    // Return agreed version
    strncpy(out->version.version, "9P2000", sizeof(out->version.version) - 1);
    out->version.version[sizeof(out->version.version) - 1] = '\0';
    
    // Reset all fids on version negotiation
    fid_destroy_all();
    
    if (s->debug) {
        fprintf(stderr, "handle_version: agreed version=%s msize=%u\n", 
                out->version.version, out->version.msize);
    }
    
    return 0;
}

int handle_auth(Server *s, Fcall *in, Fcall *out) {
    // Simple implementation - no auth required
    (void)s;
    (void)in;
    if (s->debug) {
        fprintf(stderr, "handle_auth: authentication not required\n");
    }
    return send_9p_error(out, Enoauth);
}

int handle_attach(Server *s, Fcall *in, Fcall *out) {
    if (s->debug) {
        fprintf(stderr, "handle_attach: fid=%u afid=%u uname=%s aname=%s\n",
                in->fid, in->attach.afid, in->attach.uname, in->attach.aname);
    }
    
    // Check if fid already exists
    if (fid_find(in->fid) != NULL) {
        return send_9p_error(out, Edupfid);
    }
    
    // For now, ignore authentication
    if (in->attach.afid != NOFID) {
        // Could validate auth fid here if we implemented auth
    }
    
    // Create root fid
    Fid *f = fid_create(in->fid, s->root);
    if (!f) {
        return send_9p_error(out, Enomem);
    }
    
    // Get stat for root
    if (fid_stat(f) < 0) {
        fid_destroy(f);
        return send_9p_error(out, map_errno_to_9p(errno));
    }
    
    // Return qid
    stat2qid(&f->st, &out->attach_r.qid);
    
    if (s->debug) {
        fprintf(stderr, "handle_attach: success, qid path=%llu type=0x%x\n",
                (unsigned long long)out->attach_r.qid.path, out->attach_r.qid.type);
    }
    
    return 0;
}

int handle_flush(Server *s, Fcall *in, Fcall *out) {
    // Simple implementation - nothing to flush
    (void)s;
    (void)in;
    (void)out;
    if (s->debug) {
        fprintf(stderr, "handle_flush: oldtag=%u\n", in->flush.oldtag);
    }
    return 0;
}

int handle_walk(Server *s, Fcall *in, Fcall *out) {
    if (s->debug) {
        fprintf(stderr, "handle_walk: fid=%u newfid=%u nwname=%u\n",
                in->fid, in->walk.newfid, in->walk.nwname);
        for (int i = 0; i < in->walk.nwname; i++) {
            fprintf(stderr, "  wname[%d]='%s'\n", i, in->walk.wname[i]);
        }
    }
    
    Fid *oldfid = fid_find(in->fid);
    if (!oldfid) {
        return send_9p_error(out, Eunknownfid);
    }
    
    // Check if newfid already exists (unless it's the same as fid)
    if (in->walk.newfid != in->fid && fid_find(in->walk.newfid) != NULL) {
        return send_9p_error(out, Edupfid);
    }
    
    // For empty walks (clone operation)
    if (in->walk.nwname == 0) {
        if (in->walk.newfid == in->fid) {
            // No-op, walking to same fid with no names
            out->walk_r.nwqid = 0;
            return 0;
        } else {
            // Clone fid
            Fid *newfid = fid_clone(oldfid, in->walk.newfid);
            if (!newfid) {
                return send_9p_error(out, Enomem);
            }
            out->walk_r.nwqid = 0;
            return 0;
        }
    }
    
    // Walk must be atomic - prepare temporary state
    char *temp_path = strdup(oldfid->path);
    if (!temp_path) {
        return send_9p_error(out, Enomem);
    }
    
    Qid temp_qids[16];
    int nwqid = 0;
    
    // Try to walk all names
    for (int i = 0; i < in->walk.nwname && i < 16; i++) {
        char *new_path = NULL;
        
        // Build new path
        if (strcmp(in->walk.wname[i], "..") == 0) {
            new_path = strdup(temp_path);
            if (new_path) {
                char *slash = strrchr(new_path, '/');
                if (slash && slash != new_path) {
                    *slash = '\0';
                } else {
                    strcpy(new_path, "/");
                }
            }
        } else {
            size_t len = strlen(temp_path);
            size_t namelen = strlen(in->walk.wname[i]);
            new_path = malloc(len + 1 + namelen + 1);
            if (new_path) {
                strcpy(new_path, temp_path);
                if (len > 0 && temp_path[len-1] != '/') {
                    strcat(new_path, "/");
                }
                strcat(new_path, in->walk.wname[i]);
            }
        }
        
        if (!new_path) {
            free(temp_path);
            return send_9p_error(out, Enomem);
        }
        
        // Try to walk to this path
        if (fs_walk(temp_path, in->walk.wname[i], &temp_qids[nwqid]) < 0) {
            free(new_path);
            break;  // Stop at first failure
        }
        
        // Update temporary path for next iteration
        free(temp_path);
        temp_path = new_path;
        nwqid++;
    }
    
    // Copy successful qids to response
    out->walk_r.nwqid = nwqid;
    for (int i = 0; i < nwqid; i++) {
        out->walk_r.wqid[i] = temp_qids[i];
    }
    
    if (s->debug) {
        fprintf(stderr, "handle_walk: walked %d of %d names\n", nwqid, in->walk.nwname);
    }
    
    // Only create/update fid if walk was fully successful
    if (nwqid == in->walk.nwname) {
        if (in->walk.newfid == in->fid) {
            // Update existing fid
            free(oldfid->path);
            oldfid->path = temp_path;
            temp_path = NULL;  // Don't free, we're using it
            fid_stat(oldfid);
        } else {
            // Create new fid
            Fid *newfid = fid_create(in->walk.newfid, temp_path);
            if (!newfid) {
                free(temp_path);
                return send_9p_error(out, Enomem);
            }
            fid_stat(newfid);
        }
    } else if (in->walk.newfid != in->fid) {
        // Partial walk to new fid fails per spec
        free(temp_path);
        return send_9p_error(out, Enotfound);
    }
    
    free(temp_path);
    return 0;
}

int handle_clunk(Server *s, Fcall *in, Fcall *out) {
    (void)out;
    
    if (s->debug) {
        fprintf(stderr, "handle_clunk: fid=%u\n", in->fid);
    }
    
    Fid *f = fid_find(in->fid);
    if (f) {
        fid_destroy(f);
    }
    // Per spec, clunk always succeeds even if fid not found
    return 0;
}
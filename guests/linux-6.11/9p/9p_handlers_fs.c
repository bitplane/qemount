#include "9p_handlers_fs.h"
#include "9p_fid.h"
#include "9p_fs.h"
#include "9p_errors.h"
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/stat.h>

int handle_create(Server *s, Fcall *in, Fcall *out) {
    Fid *f = fid_find(in->fid);
    if (!f) {
        return send_9p_error(out, Eunknownfid);
    }
    
    // Directory fid must be open
    if (f->omode < 0) {
        return send_9p_error(out, Ebotch);
    }
    
    // Must be a directory
    if (!S_ISDIR(f->st.st_mode)) {
        return send_9p_error(out, Ecreatenondir);
    }
    
    // Check write permission on directory
    if ((f->omode & 3) != OWRITE && (f->omode & 3) != ORDWR) {
        return send_9p_error(out, Eperm);
    }
    
    // Create the file/directory
    if (fs_create(f->path, in->create.name, in->create.perm, in->create.mode) < 0) {
        return send_9p_error(out, map_errno_to_9p(errno));
    }
    
    // Build path to new file
    char *newpath = malloc(strlen(f->path) + strlen(in->create.name) + 2);
    if (!newpath) {
        // File was created but we can't update fid - inconsistent state
        return send_9p_error(out, Enomem);
    }
    
    strcpy(newpath, f->path);
    if (f->path[strlen(f->path)-1] != '/') {
        strcat(newpath, "/");
    }
    strcat(newpath, in->create.name);
    
    // The fid now represents the new file, not the directory
    // Close the directory
    if (f->dir) {
        closedir(f->dir);
        f->dir = NULL;
    }
    f->omode = -1;
    
    // Update fid to point to new file
    free(f->path);
    f->path = newpath;
    
    // Open the new file with requested mode
    if (fid_open(f, in->create.mode) < 0) {
        // Inconsistent state - file created but can't open
        return send_9p_error(out, map_errno_to_9p(errno));
    }
    
    stat2qid(&f->st, &out->create_r.qid);
    out->create_r.iounit = s->session->msize - IOHDRSZ;
    return 0;
}

int handle_remove(Server *s, Fcall *in, Fcall *out) {
    (void)s;
    (void)out;
    
    Fid *f = fid_find(in->fid);
    if (!f) {
        return send_9p_error(out, Eunknownfid);
    }
    
    // Can't remove if file is open
    if (f->omode != -1) {
        return send_9p_error(out, Eperm);
    }
    
    if (fs_remove(f->path) < 0) {
        return send_9p_error(out, map_errno_to_9p(errno));
    }
    
    // Clunk the fid
    fid_destroy(f);
    return 0;
}
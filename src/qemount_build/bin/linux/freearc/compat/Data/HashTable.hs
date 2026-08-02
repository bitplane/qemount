module Data.HashTable (HashTable, new, lookup, insert) where

import Prelude hiding (lookup)
import Data.IORef
import qualified Data.IntMap.Strict as IntMap

data HashTable key value = HashTable
    (key -> key -> Bool)
    (key -> Int)
    (IORef (IntMap.IntMap [(key, value)]))

new :: Integral hash => (key -> key -> Bool) -> (key -> hash) -> IO (HashTable key value)
new equal hash = HashTable equal (fromIntegral . hash) <$> newIORef IntMap.empty

lookup :: HashTable key value -> key -> IO (Maybe value)
lookup (HashTable equal hash table) key = do
    buckets <- readIORef table
    return $ lookupBucket equal key (IntMap.findWithDefault [] (hash key) buckets)

insert :: HashTable key value -> key -> value -> IO ()
insert (HashTable equal hash table) key value =
    atomicModifyIORef' table $ \buckets ->
        let bucket = IntMap.findWithDefault [] (hash key) buckets
            updated = (key, value) : filter (not . equal key . fst) bucket
        in (IntMap.insert (hash key) updated buckets, ())

lookupBucket :: (key -> key -> Bool) -> key -> [(key, value)] -> Maybe value
lookupBucket _ _ [] = Nothing
lookupBucket equal key ((candidate, value):rest)
    | equal key candidate = Just value
    | otherwise = lookupBucket equal key rest

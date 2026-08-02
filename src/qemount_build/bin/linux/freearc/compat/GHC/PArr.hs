module GHC.PArr (PArr, toP, (!:)) where

import Data.Array

newtype PArr value = PArr (Array Int value)

instance Functor PArr where
    fmap function (PArr values) = PArr (fmap function values)

toP :: [value] -> PArr value
toP values = PArr (listArray (0, length values - 1) values)

(!:) :: PArr value -> Int -> value
PArr values !: index = values ! index

infixl 9 !:

module Main where
main = solution2

data Bag = Bag [Char] [Char] deriving (Show)

getMatch :: Bag -> Maybe Char
getMatch (Bag xs ys) = if any (flip elem ys) xs then Just (f xs ys) else Nothing
    where f xs = head . filter (flip elem xs)

fromStr :: String -> Bag
fromStr x = Bag (take n x) (drop n x)
        where n = flip div 2 . length $ x

indexOf :: Eq a => a -> [a] -> Maybe Int
indexOf _ []     = Nothing
indexOf x (y:ys) = if x == y then Just 0 else fmap (+1) (indexOf x ys)

doLine :: String -> Maybe Int
doLine = (>>= score)
       . getMatch . fromStr

enumer = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
score :: Char -> Maybe Int
score = fmap (+1) . flip indexOf enumer

solution1 = interact $ show . fmap sum . sequenceA . map doLine . lines

chunk :: Int -> [String] -> [[String]]
chunk w = f 0 [[]]
    where f _ x [] = x
          f d (xs:ys) zs  = if d == w then f 0 ([]:xs:ys) zs
                                      else f (d + 1) ((head zs:xs):ys) (tail zs)
doChunk :: [String] -> Maybe Int
doChunk (x:xs) = score . head $ filter (\y -> all (elem y) xs) x
solution2 = interact $ show . fmap sum . sequenceA . map doChunk . chunk 3 . lines
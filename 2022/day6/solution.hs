module Main where
main = interact solution2

unique :: Eq a => [a] -> Bool
unique = f []
    where f _ []       = True
          f acc (x:xs) | elem x acc = False
                       | otherwise  = f (x:acc) xs
dosran :: Int -> [a] -> [[a]]
dosran n x | length x < n = []
           | otherwise    = take n x : dosran n (tail x)
solution1 :: [Char] -> String
solution1 = show . fst . head . filter (unique . snd) . zip [4 ..] . dosran 4
solution2 :: [Char] -> String
solution2 = show . fst . head . filter (unique . snd) . zip [14 ..] . dosran 14
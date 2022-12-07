module Main where
main = interact solution2

unique :: Eq a => [a] -> Bool
unique = f []
    where f _ []       = True
          f acc (x:xs) | elem x acc = False
                       | otherwise  = f (x:acc) xs

solution1 :: String -> String
solution1 = show . fst . head . filter (unique . snd) . zip [4 ..] . dosran
    where dosran x | length x < 4 = []
                   | otherwise    = take 4 x : dosran (tail x)


solution2 :: String -> String
solution2 = show . fst . head . filter (unique . snd) . zip [14 ..] . dosran
    where dosran x | length x < 14 = []
                   | otherwise    = take 14 x : dosran (tail x)
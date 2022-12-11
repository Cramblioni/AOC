module Main where
main = interact solution2

chunk n [] = []
chunk n xs = take n xs : chunk n (drop n xs)

parse :: String -> [Int]
parse = f . fmap tail . span (/=' ')
    where f ("noop", _) = [0]
          f ("addx", x) = [0, read x]

indxs :: [a] -> [Int] -> [a]
indxs xs [] = []
indxs xs (y:ys) = let xs' = drop (y - 1) xs in head xs'
                                       : indxs (tail xs') (map (flip (-) y) ys)

interp = scanl (+) 1 . concat . map parse . lines

sp = [20, 60 , 100, 140, 180, 220]
solution1 = show . sum . zipWith (*) sp . flip indxs sp . interp

asChar x = if x then '#' else ' '

solution2 = unlines . map (map asChar)
          . map (zipWith (\x y -> elem x [y .. y + 2] ) [1..40])
          . chunk 40 . interp
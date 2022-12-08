module Main where
main = interact solution1
parse :: String -> [[Int]]
parse = map (map (read . (:[]))) . lines

visible xs = zipWith (>) xs (ffl xs)
ffl = tail . scanr (max) (-1)
rotate ([]:_) = []
rotate xs = reverse (map head xs) : rotate (map tail xs)

leave n xs = let n' = length xs - n in take (max n' 0) xs 

asChar x = if x then '#' else ' '

combi :: [[Bool]] -> [[Bool]] -> [[Bool]]
combi = zipWith (zipWith (||))

count :: [[Bool]] -> Int
count = sum . map (sum . map fromEnum)

step x y = combi (rotate x) (map visible y)

aggr :: (a -> a) -> [a] -> [a]
aggr f [x]    = [f x]
aggr f (x:xs) = map f (x: aggr f xs)

solution1 inp = let grid = parse inp
                    grids = take 4 . iterate rotate $ grid
                in  show . count . foldr1 combi . aggr rotate 
                  . reverse . map (map visible) $ grids

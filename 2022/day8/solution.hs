module Main where
main = interact solution2
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

-- note to self :: Focus one one case, Then map and rotate a bunch

sprint :: (a -> Bool) -> [a] -> (Bool, [a])
sprint _ [] = (True, [])
sprint f (x:xs) = if f x then fmap (x:) (sprint f xs)
                         else (False, [])

thump :: [Int] -> Int
thump [x] = 1
thump (x:xs) = let (edge, s) = length <$> sprint (<x) xs
               in s + (fromEnum . not) edge

thlump [] = []
thlump xs = max (thump xs) 1 : thlump (tail xs)

solution2 inp = let grid  = parse inp
                    grids = take 4 . iterate rotate $ grid
                    prod  = foldr1 (zipWith (zipWith (*)))
                          . aggr rotate . reverse . map (map thlump) $ grids
                in show . foldr1 (max) . map (foldr1 (max)) $ prod
                -- in unlines . map (foldr1 (++)) . map (map show)
                --   . aggr rotate . reverse . map (map thlump) $ grids
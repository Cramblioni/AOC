module Main where
main = getContents >>= solution1
parse :: String -> [[Int]]
parse = map (map (read . (:[]))) . lines

visible xs = zipWith (<) (ffl xs) xs
ffl xs = let xs' = 0 : xs ++ [-1] in init . drop 2 $ scanr (max) 0 xs'
rotate ([]:_) = []
rotate xs = map head xs : rotate (map tail xs)

leave n xs = let n' = length xs - n in take (max n' 0) xs 

asChar x = if x then '#' else ' '

combi = foldr1 (zipWith (zipWith (||)))

solution1 inp = do
    let grid = parse inp
    putStrLn "TESTING"
    let fwd = map visible grid
    let bwd = map (reverse . visible . reverse) grid
    let uwd = rotate . map (reverse . visible) $ rotate grid
    let dwd = rotate . map visible $ rotate (map reverse grid)     
    let num = sum . map (sum . map fromEnum) $ combi [fwd, bwd, uwd, dwd]
    print num
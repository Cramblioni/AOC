module Main where
main = interact $ show . parse

data Program = Prog [[Char]] [Instr] deriving (Show)
data Instr = Move Int Int Int deriving (Show)

chunk n [] = []
chunk n xs = take n xs : chunk n (drop n xs)

rotate ([]:_) = []
rotate xs = map head xs : rotate (map tail xs)

parseState = map (filter (/=' ')) . rotate . map (map (!!1)) . map (chunk 4)

parseInstr = (\[n, s, d] -> Move n s d) . map read . map last . chunk 2 . words

parse :: String -> Program
parse = f [] . lines
    where f acc ("": xs) = Prog (parseState . init $ acc) (map parseInstr xs)
          f acc (x: xs) = f (x:acc) xs

step (Prog state (cur: curs)) = undefined
    where pull n r a [] _   = (reverse a, r)
          pull n r a (x:xs)   0 = pull n (take n x) (drop n x: a) xs (pred -1)
          pull n r a (x:xs) ind = pull n r (x:a) xs (pred ind)
          put n v a [] = reverse a
          put
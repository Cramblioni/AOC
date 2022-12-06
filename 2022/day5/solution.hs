module Main where
main = interact solution1

data Program = Prog [[Char]] [Instr] deriving (Show)
data Instr = Move Int Int Int deriving (Show)

chunk n [] = []
chunk n xs = take n xs : chunk n (drop n xs)

rotate ([]:_) = []
rotate xs = map head xs : rotate (map tail xs)

parseState = ([]:) . map (filter (/=' ')) . rotate . map (map (!!1)) . map (chunk 4)

parseInstr = (\[n, s, d] -> Move n s d) . map read . map last . chunk 2 . words

parse :: String -> Program
parse = f [] . lines
    where f acc ("": xs) = Prog (parseState . init . reverse$ acc)
                              $ (map parseInstr xs)
          f acc (x: xs) = f (x:acc) xs

step (Prog state ((Move n s d): curs)) = let
            (istate, tmp) = pull n [] [] state s
            fstate = put (tmp) [] istate d -- for part 1 (reverse tmp)
        in Prog fstate curs
    where pull n r a [] _       = (reverse a, r)
          pull n r a (x:xs)   0 = pull n (take n x) (drop n x: a) xs (-1)
          pull n r a (x:xs) ind = pull n r (x:a) xs (pred ind)
          put n a []     ind = reverse a
          put n a (x:xs)   0 = put n ((n++x):a) xs (-1)
          put n a (x:xs) ind = put n (x:a) xs (pred ind)

run :: Program -> [[Char]]
run (Prog x []) = x
run (Prog s p)  = run $ step (Prog s p)

solution1 = show . map head . tail . run . parse
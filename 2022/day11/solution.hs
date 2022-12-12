module Main where
main = interact solution1

chunk n [] = []
chunk n xs = take n xs : chunk n (drop n xs)

data Expr = Add Expr Expr | Mul Expr Expr
          | Lit Int | Old | Debug String deriving Show

parseExpr :: String -> Expr
parseExpr x = case words x of
        [x]         -> atom x
        [x, "+", y] -> Add (atom x) (atom y)
        [x, "*", y] -> Mul (atom x) (atom y)
        _           -> Debug x
    where atom "old" = Old
          atom x     = Lit (read x)

data Monkey = Monkey {
    items :: [Int],
    operation :: Expr,
    test :: Int
} deriving Show
newMonkey :: [String] -> Monkey
newMonkey (items:op:test:_) = let items' = (read ('[':items++"]"))
                                  op' = (parseExpr . drop 2 . snd . span (/='=')) op
                                  test' = (read . drop 13) test
                                in Monkey items' op' test'

solution1 = unlines . map show
          . map newMonkey
          . map (map ( drop 2 . snd . span (/=':')))
          . map (init . tail) . chunk 6 . lines
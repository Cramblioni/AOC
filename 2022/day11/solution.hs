module Main where
main = interact solution1

chunk n [] = []
chunk n xs = take n xs : chunk n (drop n xs)
demaybe []           = []
demaybe (Just x: xs) = x : demaybe xs
demaybe (Nothing:xs) = demaybe xs
schlip :: [(a, b)] -> ([a], [b])
schlip []    = ([], [])
schlip ((x, y):xs) = both ((x:), (y:)) (schlip xs)

both :: (a -> b, c -> d) -> (a, c) -> (b, d)
both (f1, f2) (x1, x2) = (f1 x1, f2 x2)

data Expr = Add Expr Expr | Mul Expr Expr
          | Lit Int | Old | Debug String deriving Show

eval :: Expr -> Int -> Int
eval (Lit x) _   = x
eval (Old) x     = x
eval (Add x y) z = eval x z + eval y z
eval (Mul x y) z = eval x z * eval y z


parseExpr :: String -> Expr
parseExpr x = case words x of
        [x]         -> atom x
        [x, "+", y] -> Add (atom x) (atom y)
        [x, "*", y] -> Mul (atom x) (atom y)
        _           -> Debug x
    where atom "old" = Old
          atom x     = Lit (read x)

data Monkey = Monkey {
    items     :: [Int],
    operation :: Expr,
    test      :: Int,
    iftrue    :: Int,
    iffalse   :: Int
} deriving Show
newMonkey :: [String] -> Monkey
newMonkey (items:op:test:wt:wf:_) = let {
    items' = (read ('[':items++"]"));
    op' = (parseExpr . drop 2 . snd . span (/='=')) op;
    test' = (read . drop 13) test;
    wt' = (read . drop 16) wt;
    wf' = (read . drop 16) wf;
} in Monkey items' op' test' wt' wf'

data Pass = Pass {targ:: Int, val:: Int} deriving Show

stepSingle :: Monkey -> (Monkey, Maybe Pass)
stepSingle (Monkey [] op ts wt wf) = (Monkey [] op ts wt wf, Nothing)
stepSingle (Monkey (i:is) op ts wt wf) = let new = div (eval op i) 3
                                             tmonk = if mod new ts == 0 then wt else wf
                                   in (Monkey is op ts wt wf, Just (Pass tmonk new))

step :: Monkey -> (Monkey, [Pass])
step (Monkey [] op ts wt wf) = (Monkey [] op ts wt wf, [])
step (Monkey is op ts wt wf) = let (m', p) = stepSingle (Monkey is op ts wt wf)
                                in case p of {
                                    Nothing -> (m', []);
                                    Just x  -> fmap (x:) . step $ m'
                                }

slideStep :: Int -> Monkey -> [Pass] -> (Monkey, [Pass])
slideStep mid (Monkey is op ts wt wf) ps = let ia = map val . filter ((==mid) . targ) $ ps
                                               cp = filter ((/=mid) . targ) $ ps
                                            in fmap (++cp) . step $ (Monkey (is ++ ia) op ts wt wf)

nuke :: [Monkey] -> [Monkey]
-- slidestep, then cleanup
nuke ms = cleanup 0 . sweep 0 ms $ []
    where
       -- sweep :: Int -> [Monkey] -> [Pass] -> ([Monkey], [Pass])
          sweep i [] _ = ([], [])
          sweep i (m:ms) xs = let (m', xs') = slideStep i m xs in both ((m':), id) (sweep (i + 1) ms xs')
       -- cleanup :: Int -> ([Monkey], [Pass]) -> [Monkey]
          cleanup i (xs, []) = xs
          cleanup i ((m:ms), xs) = let mm = map val . filter ((==i) . targ) $ xs
                                       pa = filter ((/=i) . targ) xs
                                     in let (Monkey is op ts wt wf) = m in (Monkey (is ++ mm) op ts wt wf) : cleanup (i + 1) (ms, pa)

solution1 = unlines . map show
          . nuke . map newMonkey
          . map (map ( drop 2 . snd . span (/=':')))
          . map tail . chunk 7 . lines
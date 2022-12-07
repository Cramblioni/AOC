module Main where
main = interact solution2

splitCommand :: [String] -> ((String, [String]), [String])
splitCommand (x:xs) = let (body, remain) = f [] xs in ((drop 2 x, body), remain)
    where f acc [] = (reverse acc, [])
          f acc (x:xs) | head x == '$' = (reverse acc, (x:xs))
                       | otherwise     = f (x:acc) xs
parseInput :: String -> [(String, [String])]
parseInput = f . lines
    where f [] = []
          f xs = let (val, xs') = splitCommand xs in val : f xs'


step :: [String] -> [(String, [String])] -> [Entry]
step p []                             = []
step p ((c, s):xs) | c == "cd /"      = step [""] xs
                   | c == "cd .."     = step (tail p) xs
                   | take 2 c == "cd" = step (drop 3 c : p) xs
                   | c == "ls"        = mov p s ++ step p xs
mov p [] = []
mov p (x:xs) = let { [size, name] = words x ; }
               in (reverse (name : p), if size == "dir" then Nothing
                                                        else Just (read size))
                  : mov p xs

sisort :: (a -> Int) -> [a] -> (Bool, [a])
sisort f [x]      = (False, [x])
sisort f (x:y:xs) = if f x > f y then (True, y : snd (sisort f (x:xs)))
                                 else fmap (x:) (sisort f (y:xs))
misort :: (a -> Int) -> [a] -> [a]
misort f xs = let (s, xs') = sisort f xs in if s then misort f xs' else xs'

type Entry = ([String], Maybe Int)
data DirTree = Dir String [DirTree] | File String Int deriving Show

getSingle :: String -> DirTree -> Maybe DirTree
getSingle _ (File _ _) = Nothing
getSingle p (Dir _ files) = case filter (\x->p == case x of{
                                    (Dir n _) -> n;
                                    (File n _) -> n}) files of
                                [x] -> Just x
                                []  -> Nothing
get :: [String] -> DirTree -> Maybe DirTree
get [] dt = Just dt
get (x:xs) dt = (getSingle x dt) >>= get xs

extract :: String -> [Entry] -> ([Entry],[Entry])
extract s xs = (map (\(x, y) -> (tail x, y))
               $ filter ((==s) . head . fst)  xs,
               filter ((/=s) . head . fst)  xs)

collate :: [Entry] -> DirTree
collate = fst . doDir ""
    where doEntry []     = []
          doEntry ((p, Nothing):xs) = let (x, y) = doDir (head p) xs in x : doEntry y
          doEntry ((p, Just x):xs) = File (head p) x : doEntry xs
          doDir p xs = let
            (cont, xs') = extract p xs
                          in (Dir p (doEntry cont), xs')

render :: String -> DirTree -> [String]
render p (File name size) = [name ++ " - " ++ show size]
render p (Dir name files) = (p ++ name)
                        : map ("    " ++ )
                              (foldl (++) [] (map (render (p ++ name ++ "/")) files))
size :: DirTree -> Integer
size (File _ size) = toInteger size
size (Dir _ files) = sum (map size files)

sizeLim :: Integer -> DirTree -> Integer
sizeLim l = sum . f l
    -- f :: Integer -> DirTree -> [Integer]
    where f l (File _ s)    = []
          f l d             = (if size d < l then size d else 0)
                              : (\(Dir _ f) -> map (sizeLim l) f) d

solution1 = show . sizeLim 100000
          . collate . misort (length . fst). step [] . parseInput

type Stat = (String, Integer)

sMin (n1, s1) (n2, s2) = if n1 > n2 then (n2, s2) else (n1, s1)

toStat :: DirTree -> [Stat]
toStat (File _ _) = []
toStat (Dir n fs) = (n, sum (map size fs)) : foldr1 (++) (map toStat fs)

solution2 inp = let
            stats = toStat . collate . misort (length . fst)
                  . step [] . parseInput $ inp
            ((_,cur):rest) = stats
            delta = 70000000 - cur
                in show . foldr1 (sMin) $ filter ((>=30000000).(delta+).snd) rest
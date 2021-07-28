yacc -d -y 1705045.y
echo '1'
g++ -w -c -o y.o y.tab.c
echo '2'
flex 1705045.l
echo '3'
g++ -w -c -o l.o lex.yy.c
echo '4'
g++ y.o l.o -lfl
echo '5'
./a.out input.txt log.txt error.txt

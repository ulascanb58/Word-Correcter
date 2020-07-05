init :-
    retractall(list(_, _)),     %%Birleştirme işlemi
    nwords('big.txt', WordCounts),     %%Kelimeleri
    maplist(assertz, WordCounts). %% Word count listesinin her bir elemanını assert ediyor.(öne sürme)
letter(Char) :- member(Char, [a,b,c,ç,d,e,f,g,ğ,h,ı,i,j,k,l,m,n,o,ö,p,r,s,ş,t,u,ü,v,y,z]).

% nwords(+File, -WordList)
nwords(File, WordCounts) :-
 read_file_to_codes(File, Codes, []),   %% Kodlar listesinde File isimli dosyayı okur.
    maplist(char_code, Chars, Codes),
    words(Words, Chars, []),
   maplist(downcase_atom, Words, LCWords),
   count_occurrences(LCWords, WordCounts).

% Karakter listesinden bir kelime listesi döndürür
words(Words) --> blank, !, words(Words).
words([Word | Words]) --> word(Word), !, words(Words).
words([]) --> [].

word(Word) --> letters([Char | Chars]), {atom_chars(Word, [Char | Chars])}.   %% kelimede ki harflere tek tek bakmasını sağlıyor örneğin atik a = Char tik = Chars. kelime atomlarına ayrıldı

letters([L | Ls]) --> letter(L), !, letters(Ls).
letters([]) --> [].

letter(Char) --> [Char], {char_type(Char, alpha)}.  %% Charlar birer harftir, büyük yada küçük harf.

blank --> [Char], {\+ char_type(Char, alpha)}.

correct(Word,[Correct]) :-
%%repeat,read_line_to_codes(list,Line), (Line==end_of_file -> close(list),
    correct_word(Word, Knowns),
    maplist(val_key, Knowns, ValKeys),
    max_member(_:Correct, ValKeys), !.
    correct(Word, [Word]);
    (correct(Word,Correct)->(write(Correct), nl, fail); (write('Düzeltme Yapılamadı.'), nl, fail))).


correct_word(Word, [Known | Knowns]) :-
    (known([Word], [Known|Knowns])
    ; edits1(Word, Eds), known(Eds, [Known | Knowns])
    ; known_edits2(Word, [Known|Knowns])).

known(Words, Known) :- findall(W, (member(W, Words), list(W, _)), Known).

edits1(WAtom, SortedEditAtoms) :-
    findall(EditAtom, (atom_chars(WAtom, W),
            append(Start, End, W),
            append(Start, End1, Edit),
            edit_op(End, End1),
            atom_chars(EditAtom, Edit)), EditAtoms),
    sort(EditAtoms,SortedEditAtoms).


edit_op([_|End], End). % delete
edit_op([X, Y|End], [Y, X|End]). % transpose
edit_op([_|End], [L|End]) :- letter(L). % replace
edit_op(End, [L|End]) :- letter(L). % insert

known_edits2(Word, KnownUniqEds2) :-
    edits1(Word, Ed1s),
    findall(Ed2, (member(Ed1, Ed1s), edits1(Ed1, Eds2), member(Ed2, Eds2), list(Ed2, _)), KEds2),
   sort(KEds2, KnownUniqEds2).

val_key(Key, Val:Key) :- list(Key,Val).
count_occurrences(Text, Occs):- findall(list(W, Cnt), (bagof(true, member(W, Text), Ws), length(Ws,Cnt)), Occs).

count_errors(Target:WrongAtom, ErrCnt) :-
    split_string(WrongAtom, ' ', ' ', Wrong),
    maplist(atom_string, Wrongs, Wrong),
    maplist(correct, Wrongs, Corrects),
    cnt(Target, Corrects, 0, ErrCnt).
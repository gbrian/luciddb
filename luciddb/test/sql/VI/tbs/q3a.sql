set schema 's';

select KSEQ, K1K from bench100
where
Kseq between 50 and 100 
and K100K = 3
order by 1;

select KSEQ, K1K from bench100
where
Kseq between 50 and 100 
 and K40K = 3
order by 1;

select KSEQ, K1K from bench100
where
Kseq between 50 and 100 
and K10K = 3
order by 1;

select KSEQ, K1K from bench100
where
Kseq between 50 and 100 
and K1K = 3
order by 1;

select KSEQ, K1K from bench100
where
Kseq between 50 and 100 
and K100 = 3
order by 1;

select KSEQ, K1K from bench100
where
Kseq between 50 and 100 
and K10 = 3
order by 1;

select KSEQ, K1K from bench100
where
Kseq between 50 and 100 
and K5 = 3
order by 1;

select KSEQ, K1K from bench100
where
Kseq between 50 and 100 
and K4 = 3
order by 1;

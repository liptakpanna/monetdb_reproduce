--CREATE FUNCTIONS AND PROCEDURES

create or replace function needleman(ids integer, sequences text, score_gap integer, score_same integer, score_different integer) 
returns table(id1 integer, id2 integer, align1 text, align2 text, score integer) language python {
    from itertools import product
    import itertools
    from collections import deque
    
    id1, id2, align1, align2, score = [], [], [], [], []

    
    for (p,x), (q,y) in list(itertools.combinations(enumerate(sequences), 2)):
      N, M = len(x), len(y)
      
      s = lambda a, b: int(a == b)
  
      DIAG = -1, -1
      LEFT = -1, 0
      UP = 0, -1
  
      # Create tables F and Ptr
      F = {}
      Ptr = {}
  
      F[-1, -1] = 0
      for i in range(N):
          F[i, -1] = -i
      for j in range(M):
          F[-1, j] = -j
  
      option_Ptr = DIAG, LEFT, UP
      for i, j in product(range(N), range(M)):
          option_F = (
              F[i - 1, j - 1] + s(x[i], y[j]),
              F[i - 1, j] - 1,
              F[i, j - 1] - 1,
          )
          F[i, j], Ptr[i, j] = max(zip(option_F, option_Ptr))
  
      # Work backwards from (N - 1, M - 1) to (0, 0)
      # to find the best alignment.
      alignment = deque()
      i, j = N - 1, M - 1
      while i >= 0 and j >= 0:
          direction = Ptr[i, j]
          if direction == DIAG:
              element = i, j
          elif direction == LEFT:
              element = i, None
          elif direction == UP:
              element = None, j
          alignment.appendleft(element)
          di, dj = direction
          i, j = i + di, j + dj
      while i >= 0:
          alignment.appendleft((i, None))
          i -= 1
      while j >= 0:
          alignment.appendleft((None, j))
          j -= 1
  
      first = "".join(
          "-" if i is None else x[i] for i, _ in alignment
      )
      second = "".join(
          "-" if j is None else y[j] for _, j in alignment
      )
      
      curr_score = 0
      for i, j in alignment:
          if (i is None) or (j is None):
              curr_score += score_gap[0]
          elif x[i] == y[j]:
              curr_score += score_same[0]
          elif x[i] != y[j]:
              curr_score += score_different[0]
              
      id1.append(ids[p])
      id2.append(ids[q])
      align1.append(first)
      align2.append(second)
      score.append(curr_score)
      
    
    result = dict()
    result['id1'] = id1
    result['id2'] = id2
    result['align1'] = align1
    result['align2'] = align2
    result['score'] = score
    
    return result
};

create or replace function create_lookup(align1 text, align2 text, score_gap integer, score_same integer, score_different integer, threshold integer, k integer) 
returns table(align1 text, align2 text, score integer) language python {

  k = k[0]
  kmers1, kmers2, score = [], [], [] 
  
  for i in range(len(align1)):
    al1, al2 = align1[i], align2[i]
    
    for j in range(len(al1)-k+1):
      kmer1 = al1[j:j+k]
      kmer2 = al2[j:j+k]
      
      curr_score = 0
      for p in range(k):
        if al1[j+p] == al2[j+p]:
          curr_score += score_same[0]
        elif al1[j+p] == '-' or al2[j+p] == '-':
          curr_score += score_gap[0]
        else:
          curr_score += score_different[0]
        
      if curr_score >= threshold[0]:
        kmers1.append(kmer1)
        kmers2.append(kmer2)
        score.append(curr_score)
        
  return [kmers1, kmers2, score]

};

create or replace function get_subids(seqid integer)
returns table(subid integer, ind integer)
begin
  return select distinct s.id as subid, charindex(s.seq, e.seq) as ind
  from seq_data e cross join aligned_subseq s 
  where e.id = seqid
  AND charindex(s.seq, e.seq) > 0
  order by subid;
end;

create or replace function get_common_subaligns(x1 integer, x2 integer)
returns table(id integer, align1 text, align2 text, score integer, ind1 integer, ind2 integer, first integer)
begin
  return with tmp as (
    select s1.ind ind1, s2.ind ind2, s1.subid sub1, s2.subid sub2 from get_subids(x1) s1 cross join get_subids(x2) s2
  )
  (select id, align1, align2, score, ind1, ind2, 1 as first from lookup join tmp 
    on seqid1 = sub1 and seqid2 = sub2
  )
  union distinct
  (select id, align1, align2, score, ind1, ind2, 2 as first from lookup join tmp 
    on seqid1 = sub2 and seqid2 = sub1
    where not align1 = align2 
  )
  order by score desc;
end;

create or replace function use_subalign(ids integer, align1 text, align2 text, score integer, ind1 integer, ind2 integer, first integer, s1 text, s2 text)
returns text
language python {
from itertools import product
import itertools
from collections import deque

def align(x,y):  
    score_same, score_gap, score_different = 1, -2, -1
    N, M = len(x), len(y)
    
    s = lambda a, b: int(a == b)

    DIAG = -1, -1
    LEFT = -1, 0
    UP = 0, -1

    # Create tables F and Ptr
    F = {}
    Ptr = {}

    F[-1, -1] = 0
    for i in range(N):
        F[i, -1] = -i
    for j in range(M):
        F[-1, j] = -j

    option_Ptr = DIAG, LEFT, UP
    for i, j in product(range(N), range(M)):
        option_F = (
            F[i - 1, j - 1] + s(x[i], y[j]),
            F[i - 1, j] - 1,
            F[i, j - 1] - 1,
        )
        F[i, j], Ptr[i, j] = max(zip(option_F, option_Ptr))

    # Work backwards from (N - 1, M - 1) to (0, 0)
    # to find the best alignment.
    alignment = deque()
    i, j = N - 1, M - 1
    while i >= 0 and j >= 0:
        direction = Ptr[i, j]
        if direction == DIAG:
            element = i, j
        elif direction == LEFT:
            element = i, None
        elif direction == UP:
            element = None, j
        alignment.appendleft(element)
        di, dj = direction
        i, j = i + di, j + dj
    while i >= 0:
        alignment.appendleft((i, None))
        i -= 1
    while j >= 0:
        alignment.appendleft((None, j))
        j -= 1

    first = "".join(
        "-" if i is None else x[i] for i, _ in alignment
    )
    second = "".join(
        "-" if j is None else y[j] for _, j in alignment
    )
    
    curr_score = 0
    for i, j in alignment:
        if (i is None) or (j is None):
            curr_score += score_gap
        elif x[i] == y[j]:
            curr_score += score_same
        elif x[i] != y[j]:
            curr_score += score_different
  
    return first, second, curr_score

def check_intersect(arr, ind, k):
    summa = sum(arr[ind:ind+k])
    if summa > 0:
      return False
    else:
      arr[ind:ind+k] = [1] * k
      return True
try:     
  seq1 = list(s1)
  seq2 = list(s2)
  
  used1 = [0] * len(seq1)
  used2 = [0] * len(seq2)


  for i in range(len(ids)):
      k = len(align1[i])
      
      if first[i] == 1:
        curr_ind1, curr_ind2 = ind1[i]-1, ind2[i]-1 #IND WITH NO ZERO
        curr_align1, curr_align2 = align1[i], align2[i]
      else:
        curr_ind1, curr_ind2 = ind1[i]-1, ind2[i]-1 #IND WITH NO ZERO
        curr_align1, curr_align2 = align2[i], align1[i]
      
      if check_intersect(used1, curr_ind1, k) and check_intersect(used2, curr_ind2, k):
        plusind1 = sum(used1[0:curr_ind1])
        plusind2 = sum(used2[0:curr_ind2])
      
        if plusind1 > 0 or plusind2 > 0:
          curr_ind1, curr_ind2 = curr_ind1-plusind1+int(plusind1/k), curr_ind2-plusind2+int(plusind2/k)
  
        seq1[curr_ind1] = '[' + curr_align1 + "#" + str(score[i]) + ']'
        seq2[curr_ind2] = '[' + curr_align2 + ']'
        
        for j in range(k-1):
            seq1.pop(curr_ind1+1)
            seq2.pop(curr_ind2+1)

  seq1 = ''.join(seq1)
  seq2 = ''.join(seq2)
  
  res1, res2, score = '', '', 0
  
  while '[' in seq1:
      i1 = seq1.find('[') 
      i2 = seq2.find('[')
      j1 = seq1.find(']') 
      j2 = seq2.find(']')
      
      first, sec, currscore = align(seq1[:i1], seq2[:i2])
      
      tmp = seq1[i1+1:j1].split("#")
      
      res1 += first + tmp[0]
      res2 += sec + seq2[i2+1:j2]
      score += currscore + int(tmp[1])
      
      seq1, seq2 = seq1[j1+1:], seq2[j2+1:]
      
  first, sec, currscore = align(seq1, seq2)
  res1 += first
  res2 += sec
  score += currscore
  
  return res1 +" , " + res2 + " , " +str(score)

except Exception as e:
  return 'ERROR'
};

CREATE OR REPLACE FUNCTION mysample()
RETURNS TABLE(id integer, seq text)
BEGIN
   RETURN
     select id, seq from seq_data limit 10;
end;

create or replace procedure update_lookup(score_match integer, score_gap integer, score_mis integer, k integer)
begin
  truncate table aligned_subseq;
  truncate table lookup;
  truncate table sample_seq;
  
  insert into sample_seq (SELECT * FROM mysample());
  
  insert into lookup(align1, align2, score)
  select * from create_lookup((select align1, align2, score_gap, score_match, score_mis, floor(k/2)+1, k 
  from needleman((select id, seq, score_gap, score_match, score_mis
  from sample_seq ))));

  insert into aligned_subseq(seq) 
  select * from (
  (select replace(align1, '-', '') as "s" from lookup)
  union distinct 
  (select replace(align2, '-', '') as "s" from lookup)
  ) as u
  where not exists (select x.seq from aligned_subseq x where x.seq=u.s);
  
  update lookup set seqid1 = (select id from aligned_subseq where aligned_subseq.seq = replace(align1, '-', '')),
  seqid2 = (select id from aligned_subseq where aligned_subseq.seq = replace(align2, '-', ''));
end;

create or replace function use_lookup(id1 integer, id2 integer, score_match integer, score_gap integer, score_mis integer)
returns text
begin
  declare result text, seq1 text, seq2 text;
  
  select seq into seq1 from seq_data where id = id1;
  select seq into seq2 from seq_data where id = id2;
  
  select use_subalign(id,align1,align2,score,ind1,ind2,first, seq1, seq2) into result
  from get_common_subaligns(id1,id2) where not abs(ind1-ind2)*2 > score;
  
  return result;
end;


  -- CREATING TABLES
  create table seq_data (id serial, seq varchar(150));
  
  create table aligned_subseq(id serial, seq varchar(20));

  create table lookup(id serial, seqid1 int, align1 varchar(20), seqid2 int, align2 varchar(20), score integer);

  create table sample_seq(id integer, seq text);

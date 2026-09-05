alter table customers add primary key (customer_id);
alter table accounts add primary key (account_id);
alter table accounts add foreign key (customer_id) references customers(customer_id);
alter table transactions add primary key (txn_id);
alter table transactions add foreign key (from_account_id) references accounts(account_id);
alter table transactions add foreign key (to_account_id) references accounts(account_id);
create index idx_txn_from on transactions(from_account_id, txn_timestamp);
create index idx_txn_to on transactions(to_account_id, txn_timestamp);

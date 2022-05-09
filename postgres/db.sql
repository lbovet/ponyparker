create table if not exists users (
    user_id varchar primary key,
    creation_time timestamp,
    token varchar,
    display_name varchar
);

create table if not exists events (
    insert_order serial,
    creation_time timestamp,
    json varchar
);
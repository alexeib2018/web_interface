CREATE TABLE public.change_log (
    id integer NOT NULL,
    account text,
    table_changed text,
    action text,
    new_value text,
    old_value text,
    ip text,
    created timestamp without time zone DEFAULT now()
);

CREATE SEQUENCE public.change_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.change_log_id_seq OWNED BY public.change_log.id;

ALTER TABLE ONLY public.change_log ALTER COLUMN id SET DEFAULT nextval('public.change_log_id_seq'::regclass);

SELECT pg_catalog.setval('public.change_log_id_seq', 1, false);

ALTER TABLE ONLY public.change_log
    ADD CONSTRAINT change_log_pkey PRIMARY KEY (id);

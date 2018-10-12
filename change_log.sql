CREATE TABLE public.change_log (
    id integer NOT NULL,
    email text NOT NULL,
    table_changed text NOT NULL,
    action text NOT NULL,
    old_value text NOT NULL,
    new_value text NOT NULL,
    created date DEFAULT now()
);

CREATE SEQUENCE public.change_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.change_log_seq OWNED BY public.change_log.id;

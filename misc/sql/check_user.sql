CREATE OR REPLACE FUNCTION public.check_user() RETURNS void AS $$
BEGIN
  /*IF current_user = 'web_anon' THEN*/
  IF current_setting('request.jwt.claim.team', true) = 'evil' THEN
    RAISE EXCEPTION 'No, you are evil team'
      USING HINT = 'Stop being so evil and maybe you can log in';
  END IF;
END
$$ LANGUAGE plpgsql;

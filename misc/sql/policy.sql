DROP POLICY IF EXISTS is_team ON api.submissions;
CREATE POLICY is_team ON api.submissions
    USING (team = current_setting('request.jwt.claim.team', true))
    WITH CHECK (team = current_setting('request.jwt.claim.team', true))
;

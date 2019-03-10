DROP POLICY IF EXISTS chat_policy ON chat;
CREATE POLICY chat_policy ON chat
    USING ((message_to = current_user) OR (message_from = current_user))
    WITH CHECK (message_from = current_user)
;

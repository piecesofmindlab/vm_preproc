function uuid = getUUID()
% Usage: uuid = getUUID()
% 
% Stand-in for mlabSTRFdb if it does not exist. 
uuid = 1;
while sum(uuid<30)
    % Check for invisible newline character at beginning
    [~,UUID] = system('uuidgen');
    uuid = strrep(lower(UUID(1:end-1)),'-',''); % end-1 because the system adds a newline character
end

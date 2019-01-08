%% Backgammon strategy simulations
% Mike Flanigan
% 1/1/19

clear; clc; close all

run_plotting_on = true;

num_pieces = 15; 
bank_spots = 6;
home = 0;

MC_sims = 500;

% init bank histories for play animation later
bankS1_hist = zeros(6,50,MC_sims);
bankS2_hist = zeros(6,50,MC_sims);

for jj = 1:MC_sims
    % bank is a 6x1 vector representing number of pieces in each spot
    bankS1 = initialize_bank(num_pieces); % fxn to randomly distribute starting pieces
    bankS2 = bankS1;

    bankS1_hist(:,1,jj) = bankS1; % matrix of bank values over roll count
    bankS2_hist(:,1,jj) = bankS1; % matrix of bank values over roll count

    % ------------- strategy 1 (accepted human strategy) --------------------
    game_play = true;
    k = 1;
    while game_play
        % roll the dice
        die_roll = sort(randi(6,2,1)); % 2x1, smaller value first
        die_roll_hist(:,k) = die_roll;

        % check for doubles
        if die_roll(1) == die_roll(2)
            doubles = true;
            moves = 4;
        else
            doubles = false;
            moves = 2;
        end
        
        %{
        note, this type of strategy programming would benefit significantly
        from a flow / tree decision diagram coupled with a state machine
        for programming and debugging. 
        Also a visualization of specific hands with both strategies,
        similar rolls visualized, and the actual moves played out would be
        a very cool way to understand and present all of it.
        %}

        r = 2;
        while moves > 0
            % check if the game is over 
            if all(bankS1 == 0)
%                 disp('game over!')
                break
            end
            % ---- if the game isn't over, make a move

            % if there is a piece in the rolled bank spot, send it home
            if bankS1(die_roll(r)) > 0
                bankS1(die_roll(r)) = bankS1(die_roll(r)) - 1;
                home = home + 1;

            % if there isn't a piece in the bank spot, search uphill and
            % find a piece to send down, if that doesn't exist then search for
            % a piece downhill to score with
            else
                spot = die_roll(r);
                found_a_move = false;
                while ~found_a_move && spot < 6
                    spot = spot+1; % look uphill
                    % found a spot uphill with a piece that can be moved down
                    if bankS1(spot) > 0
                        bankS1(spot) = bankS1(spot) - 1;
                        bankS1(spot-die_roll(r)) = bankS1(spot-die_roll(r)) + 1;
                        found_a_move = true;
                    end
                end  

                % if no uphill move was found, then score a downhill piece
                spot = die_roll(r);
                while ~found_a_move && spot > 1
                    spot = spot-1; % look downhill
                    % found a spot downhill with a piece that can be scored
                    if bankS1(spot) > 0
                        bankS1(spot) = bankS1(spot) - 1;
                        home = home + 1;
                        found_a_move = true;
                    end
                end    
            end

            moves = moves - 1;

            if doubles
                if mod(moves,2)==0
                    r = r -1;
                end
            else
                r = r - 1;
            end
        end

        bankS1_hist(:,k+1,jj) = bankS1;

        % check if the game is over 
        if all(bankS1 == 0)
%             disp('game over!')
            break
        end

        k = k+1; % update roll count
    end

    % ------------- strategy 2 --------------------
    game_play = true;
    k2 = 1;
    while game_play
        % roll the dice
        if k > k2 
            die_roll = die_roll_hist(:,k2);
        else
            die_roll = sort(randi(6,2,1)); % 2x1, smaller value first
        end

        % check for doubles
        if die_roll(1) == die_roll(2)
            doubles = true;
            moves = 4;
        else
            doubles = false;
            moves = 2;
        end

        r = 2;
        while moves > 0

            % check if the game is over 
            if all(bankS2 == 0)
%                 disp('game over!')
                break
            end
            % ---- if the game isn't over, make a move

            % start at the top and look for downhill moves
            spot = 6;
            found_a_move = false;
            while ~found_a_move && spot > 0 && spot > die_roll(r)
                if bankS2(spot) > 0
                    bankS2(spot) = bankS2(spot) - 1;
                    bankS2(spot-die_roll(r)) = bankS2(spot-die_roll(r)) + 1;
                    found_a_move = true;
                end
                spot = spot - 1;
            end

            % if didn't find a downhill odds increasing move then score
            % if there is a piece in the bank spot, send it home
            if ~found_a_move && bankS2(die_roll(r)) > 0
                bankS2(die_roll(r)) = bankS2(die_roll(r)) - 1;
                home = home + 1;             
            end
            
            % if didn't find a downhill odds increasing and there isn't a 
            % piece in the bank spot, search downhill for a piece to score            
            spot = die_roll(r);
            while ~found_a_move && spot > 1
                    spot = spot-1; % look downhill
                    % found a spot downhill with a piece that can be scored
                    if bankS2(spot) > 0
                        bankS2(spot) = bankS2(spot) - 1;
                        home = home + 1;
                        found_a_move = true;
                    end
            end

            moves = moves - 1;

            if doubles
                if mod(moves,2)==0
                    r = r -1;
                end
            else
                r = r - 1;
            end
        end

        bankS2_hist(:,k2+1,jj) = bankS2;

        % check if the game is over 
        if all(bankS2 == 0)
%             disp('game over!')
            break
        end

        k2 = k2+1; % update roll count
    end

    S1_hist(jj) = k;
    S2_hist(jj) = k2;
end

%% plotting of Monte carlo runs
figure()
histogram(S1_hist,[0.5:1:15.5])
hold on
histogram(S2_hist,[0.5:1:15.5])
legend('default strategy','move low strategy')
xlabel('number of turns to finish the game')
ylabel('number of MC simulations')

disp(['default strategy mean rolls over 500 MC runs: ',num2str(mean(S1_hist-1))])
disp(['go low strategy mean rolls over 500 MC runs: ',num2str(mean(S2_hist-1))])

pause_t = 0.1; % seconds between visualizing each turn
run_plotting_on = false;
if run_plotting_on
        figure()
        for jj = 1:MC_sims
            flag = 0;
            clf
            sgtitle({[num2str(jj),'th Monte Carlo simulation']})
            for ii = 1:50
                subplot(2,1,1)
                cla
                bar(bankS1_hist(:,ii,jj))
                ylim([0,10])
        %         txt = strcat('die roll: ',num2str(die_roll(1)),',',num2str(die_roll(2)));
        %         text(5,12,txt)
                title('default strategy')
                ylabel('pieces in spot')
                xlabel('bank position')

                subplot(2,1,2)
                bar(bankS2_hist(:,ii,jj))
                ylim([0,10])
        %         txt = strcat('die roll: ',num2str(die_roll(1)),',',num2str(die_roll(2)));
        %         text(5,12,txt)
                title('go low strategy')
                ylabel('pieces in spot')
                xlabel('bank position')
                drawnow;
                pause(pause_t);
                
                if all(bankS1_hist(:,ii,jj)==0) && all(bankS2_hist(:,ii,jj)==0)
                    if flag == 1
                        break
                    end
                    flag = flag + 1;
                end
            end
        end
end

go_low_win_vector = zeros(MC_sims,1);
go_low_win_bank = zeros(6,1);
default_win_bank = zeros(6,1);
% figure()
for jj = 1:MC_sims
    for ii = 1:50
        if all(bankS2_hist(:,ii,jj)==0) && ~all(bankS1_hist(:,ii,jj)==0)
            go_low_win_vector(jj) = 1;

            if bankS1_hist(:,1,jj) ~= bankS2_hist(:,1,jj)
                disp('PROBLEM')
                pause(2)
            end
            
%             cla     
%             subplot(2,1,2)
%             bar(bankS1_hist(:,1,jj))
%             ylim([0,10])
%             drawnow
%             pause(0.1)
             
            go_low_win_bank = go_low_win_bank + bankS1_hist(:,1,jj);
            break
        elseif all(bankS1_hist(:,ii,jj)==0) && ~all(bankS2_hist(:,ii,jj)==0)
            % plotting situations where the default won
%             cla
%             subplot(2,1,1)
%             bar(bankS1_hist(:,1,jj))
%             ylim([0,10])
%             drawnow
%             pause(0.1)
            
            default_win_bank = default_win_bank + bankS1_hist(:,1,jj);
            break
        end
    end
end
% figure()
% histogram(go_low_win_bank,[0.5:1:15.5])
% bar(go_low_win_bank)

%% function defines
function x0 = initialize_bank(num_pieces)
    % randomly fill each bank spot with up to the maximum number of pieces
    x0 = randi(num_pieces,6,1);

    % check if the total number of pieces in the bank exceeds the number of
    % pieces on the board
    too_many_pieces = sum(x0)>num_pieces;

    if too_many_pieces
        % normalize the number of pieces in each bank spot so the total is
        % equal to the number of board pieces
        denominator = sum(x0)/num_pieces;
        x0 = round(x0/denominator);

        if sum(x0) < num_pieces
            rand_bank_spot = randi(6);
            x0(rand_bank_spot) = x0(rand_bank_spot) + 1;
        elseif sum(x0) > num_pieces
            rand_bank_spot = randi(6);
            while x0(rand_bank_spot) <= 0 
                rand_bank_spot = randi(6);
            end
            x0(rand_bank_spot) = x0(rand_bank_spot) - 1;
        end
    end
end
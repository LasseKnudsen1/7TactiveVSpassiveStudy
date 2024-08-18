function  maxSums_permutedDistribution = test_by_permutation_4oneSided(profiles_condition1, profiles_condition2, num_permutations)
    % Set the significance threshold
    Threshold = 0.05;

    % Initialize the matrix to store the maximum sums from permutations
    maxSums_permutedDistribution = zeros(num_permutations, 2);
    for k = 1:num_permutations
        % Generate random binary matrices to shuffle conditions
        Matrix_rand1 = rand(size(profiles_condition1,1), 1) > 0.5;
        Matrix_rand2 = 1 - Matrix_rand1;
        Matrix1 = repmat(Matrix_rand1, 1, size(profiles_condition1, 2));
        Matrix2 = repmat(Matrix_rand2, 1, size(profiles_condition2, 2));
        
        % Apply the shuffling to create permuted datasets
        temp_Permutation1 = profiles_condition1 .* Matrix2 + profiles_condition2 .* Matrix1;
        temp_Permutation2 = profiles_condition1 .* Matrix1 + profiles_condition2 .* Matrix2;

        % Perform t-test on the permuted data
        [~, med_P, ~, stats] = ttest(temp_Permutation1 - temp_Permutation2);
        
        % Calculate the max positive and negative sums for each permutation
        [posSum, negSum] = check_maxSum(med_P, Threshold, stats.tstat);
        maxSums_permutedDistribution(k, :) = [posSum, negSum];
    end

end

function [maxPosSum, maxNegSum] = check_maxSum(P_Ttest, Threshold, tvals)
    % Initialize variables to track max sums
    i = 1;
    maxPosSum = 0;
    maxNegSum = 0;
    currentSum = 0;
    startPointer = 0;

    % Iterate through p-values to find significant clusters
    while i <= numel(P_Ttest)
        if P_Ttest(i) <= Threshold
            if startPointer == 0  % Start of a new cluster
                    startPointer = i;
                    currentSum = tvals(i);
            else  % Continue adding to the current cluster
                if sign(tvals(i)) == sign(currentSum)
                    currentSum = currentSum + tvals(i);
                else  % Reset cluster if signs differ (for one-sided)
                    startPointer = i;
                    currentSum = tvals(i);
                end
            end
            % Update max sums if current cluster sum exceeds previous max
            if  currentSum > maxPosSum
                maxPosSum = currentSum;
            elseif currentSum < maxNegSum
                maxNegSum = currentSum;
            end
        else  % Reset if the layer is not significant
            startPointer = 0;
            currentSum = 0;
        end
        i = i + 1;
    end
end


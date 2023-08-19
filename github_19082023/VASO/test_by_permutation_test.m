function [ P_test_final , length_permutation_test ] = test_by_permutation_test( profiles_condition1 , profiles_condition2 , num_permutations )
% test low contrast 4 layer AM

Threshold = 0.05;
P_Ttest_ori = []; 

[~,P_Ttest_ori,~,stats] = ttest(profiles_condition1-profiles_condition2);
P_Ttest_ori = P_Ttest_ori';
length_ori = check_length_significance(P_Ttest_ori,Threshold,stats.tstat);

length_permutation_test = [];
for i = 1:num_permutations
    Matrix_rand1 = rand(size(profiles_condition1,1),1);
    Matrix_rand1(Matrix_rand1>0.5) = 1;
    Matrix_rand1(Matrix_rand1<=0.5) = 0;
    Matrix_rand2 = 1-Matrix_rand1;
    Matrix1 = []; Matrix2 = [];
    for j = 1:size(profiles_condition1,2)
        Matrix1 = [Matrix1 Matrix_rand1];
        Matrix2 = [Matrix2 Matrix_rand2];
    end
    temp_Permutation1 = profiles_condition1.*Matrix2+profiles_condition2.*Matrix1;
    temp_Permutation2 = profiles_condition1.*Matrix1+profiles_condition2.*Matrix2;
    

    [~,med_P,~,stats] = ttest(temp_Permutation1-temp_Permutation2);
    med_P = med_P';
    
    length_permutation_test = [length_permutation_test; check_length_significance(med_P,Threshold,stats.tstat)];
end


P_test_final = sum(length_permutation_test>=length_ori)/num_permutations;

end


function [ length ] = check_length_significance( P_Ttest , Threshold , tvals )

i = 1;
max_length = 0;
max_lengthSum = 0;
startPointer = 0;
endPointer = 0;
while i<=size(P_Ttest,1)
    %enter if current layer is significant
    if P_Ttest(i)<=Threshold 
        %Enter if previous layer was also significant
        if endPointer ~= 0 
            endPointer = i; %Set pointer to current layer
            if max_length<endPointer-startPointer+1
                max_length = endPointer-startPointer+1;
            end
            if sum(tvals(startPointer:endPointer))>max_lengthSum
                max_lengthSum=sum(tvals(startPointer:endPointer));
            end
        %Enter if current layer is start of cluster    
        else
            startPointer = i;
            endPointer = i;
            if max_length<endPointer-startPointer+1
                max_length = endPointer-startPointer+1;
            end
            if sum(tvals(startPointer:endPointer))>max_lengthSum
                max_lengthSum=sum(tvals(startPointer:endPointer));
            end
        end
    
        
    %Enter if current layer is non-significant
    else
        %Enter if current layer is adjacent to significant
        %cluster to reset pointers.
        if endPointer ~= 0
            if max_length<endPointer-startPointer+1
                max_length = endPointer-startPointer+1;
            end
            if sum(tvals(startPointer:endPointer))>max_lengthSum
                max_lengthSum=sum(tvals(startPointer:endPointer));
            end
            startPointer = 0;
            endPointer = 0;
        end
    end
    i = i+1;
end
length = max_lengthSum;

end



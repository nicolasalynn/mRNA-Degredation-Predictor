%% Create model here
clear, clc

load('data_sets/challenge_data/miR_validation.mat')

addpath nico_functions
addpath lotem_functions
addpath michal_functions

%  Pull Data  --- THIS DOES NOT HAVE TO BE TOUCHED

clear, clc 
challenge_path = 'data_sets/validation_data/';

load('data_sets/challenge_data/genes_validation.mat');
gene_validation = genes;


miRs_validation = load('data_sets/challenge_data/miR_validation.mat');
mirs_validation(1,:) = keys(miRs_validation.miRs);
mirs_validation(2,:) = values(miRs_validation.miRs);


save(strcat(challenge_path, 'gene_validation_use.mat'), 'gene_validation');
save(strcat(challenge_path, 'mirs_validation_use.mat'), 'mirs_validation');


%% Find the first instance of miRNA mRNA binding for each combination (Nico)
clear, clc

load('data_sets/validation_data/mirs_validation_use.mat')
load('data_sets/validation_data/gene_validation_use.mat')


run_initiation = input("Do you want to recalculate the miRNA-mRNA binding "  +  ...
"indices? This action will take approximatelly 2 minutes... \n([Y] = 1, [N] = 0):  ");

mirs_validation = mirs_validation(2, :);

if run_initiation 
    fprintf("\nThis will take a minute...\n\n");
    fake_repression = array2table(ones(size(gene_validation, 1), 2));
    temp = binding_indices_validation(mirs_validation, gene_validation, 'data_sets/validation_data/');

end
clearvars run_initiation

%%

clear, clc

load('data_sets/validation_data/true_indices.mat')
load('data_sets/validation_data/gene_validation_use.mat')

get_gene_windows(gene_validation,true_indices, 'validation_windows', 74, "validation");

%%
clear, clc
load('data_sets/validation_data/reshaped_validation_windows.mat')

find_folding_energies(windows_reshaped, "validation");
 
%%

clear, clc

reshaped_indices = load('data_sets/validation_data/reshaped_indices.mat');
regression_lengths = load('data_sets/validation_data/total_lengths.mat');

[terminus_distance_one, terminus_distance_two] = ...
    distance_edge(reshaped_indices.reshaped_indices, regression_lengths.lengths_reshaped, "validation");

save('data_sets/validation_data/terminus_distance_one.mat', 'terminus_distance_one')
save('data_sets/validation_data/terminus_distance_two.mat', 'terminus_distance_two')
%%

clear, clc

clear, clc
load('data_sets/validation_data/reshaped_validation_windows.mat');
load('data_sets/challenge_data/codon_CAI.mat')

%reshaped_nt_windows.mat is windows_reshaped
Sequences_ORF = windows_reshaped{1,2};
CAI_ORF = CAI_generator(Sequences_ORF,codon_CAI);
Sequences_UTR5 = windows_reshaped{1,1};
CAI_UTR5 = CAI_generator(Sequences_UTR5,codon_CAI);
Sequences_UTR3 = windows_reshaped{1,3};
CAI_UTR3 = CAI_generator(Sequences_UTR3,codon_CAI);

cai_reshaped = cell(1, 3);
cai_reshaped{1, 1} = CAI_UTR5;
cai_reshaped{1, 2} = CAI_ORF;
cai_reshaped{1,3} = CAI_UTR3;

clearvars ans CAI_ORF CAI_UTR3 CAI_UTR5 Sequences_ORF Sequences_UTR3 Sequences_UTR5 titles windows_reshaped i codon_CAI 
save('data_sets/validation_data/cai_reshaped.mat', 'cai_reshaped')

%%

clear, clc

load('data_sets/validation_data/reshaped_validation_windows.mat');
Sequences_ORF = windows_reshaped{1,2};
GC_content_ORF = GC_content_generator(Sequences_ORF);
Sequences_UTR5 = windows_reshaped{1,1};
GC_content_UTR5 = GC_content_generator(Sequences_UTR5);
Sequences_UTR3 = windows_reshaped{1,3};
GC_content_UTR3 = GC_content_generator(Sequences_UTR3);

gc_reshaped = cell(1, 3);
gc_reshaped{1, 1} = GC_content_UTR5;
gc_reshaped{1, 2} = GC_content_ORF;
gc_reshaped{1,3} = GC_content_UTR3;

clearvars ans CAI_ORF CAI_UTR3 CAI_UTR5 Sequences_ORF Sequences_UTR3 Sequences_UTR5 titles windows_reshaped i codon_CAI 
save('data_sets/validation_data/gc_reshaped.mat', 'gc_reshaped')


%%
clear, clc

load('data_sets/validation_data/whole_sequence.mat')

regression_lengths = cell(1, 3);
for i = 1:3
    seqs = whole_reshaped{i};
    lengths = zeros(1, length(seqs));
    for j = 1:length(seqs)
        lengths(j) = strlength(seqs(j));
    end
    regression_lengths{i} = lengths;
end
save('data_sets/validation_data/regression_lengths.mat', 'regression_lengths')


%%

clear, clc

load('data_sets/validation_data/conservations.mat')
load('data_sets/validation_data/folding_energies.mat')
load('data_sets/validation_data/lengths_from_end.mat')
load('data_sets/validation_data/lengths_from_either.mat')
load('data_sets/validation_data/cai_reshaped.mat')
load('data_sets/validation_data/regression_lengths.mat')
load('data_sets/validation_data/gc_reshaped.mat')
load('data_sets/validation_data/terminus_distance_one.mat')
load('data_sets/validation_data/terminus_distance_two.mat')
load('regression_models/lasso_model.mat')
load('regression_models/stepwise_model.mat')
clearvars ans dim i index_data length_data method disatnce_cell_tot distance_cell_end

lasso_y_pred = cell(1, 3);

%% LASSO MODEL

for i = 1:3
   
    X = [cai_reshaped{i}', conservation{i}', gc_reshaped{i}',reshaped_indices{i}', terminus_distance_one{i}', folding_energies{i}'];
    coef = lasso_model{i}.coef;
    coef0 = lasso_model{i}.coef0;
    lasso_y_pred{i} = coef' * X' + coef0;  
    stepwise_y_pred{i} = predict(stepwise_model{i}, X); 
    
end

save('validation_predictions/lasso_y_pred.mat', 'lasso_y_pred');
save('validation_predictions/stepwise_y_pred.mat', 'stepwise_y_pred');











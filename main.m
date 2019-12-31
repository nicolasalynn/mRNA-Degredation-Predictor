clear, clc
%%  Genetic Supression Predictor -- RUN ME
%   Goal: To predict mRNA degradation and supression as a result of miRNA
%   interaction.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath nico_functions
addpath lotem_functions
addpath michal_functions

%  Pull Data  --- THIS DOES NOT HAVE TO BE TOUCHED

clear, clc 

codon_weights = load('data_sets/challenge_data/codon_weights.mat'); 

codon_CAI(1,:) = keys(codon_weights.CAI_weights);
codon_CAI(2,:) = values(codon_weights.CAI_weights);
codon_tAI(1,:) = keys(codon_weights.tAI_weights);
codon_tAI(2,:) = values(codon_weights.tAI_weights);

clearvars codon_weights

gene_training = load('data_sets/challenge_data/genes_training.mat');
gene_training = gene_training.genes;


miRs_training = load('data_sets/challenge_data/miRs_training.mat');
mirs_training(1,:) = keys(miRs_training.miRs);
mirs_training(2,:) = values(miRs_training.miRs);

clearvars miRs_training
temp = load('data_sets/challenge_data/repress.mat');
repress = temp.repress;
clearvars temp
%% Find the first instance of miRNA mRNA binding for each combination (Nico)

run_initiation = input("Do you want to recalculate the miRNA-mRNA binding "  +  ...
"indices? This action will take approximatelly 2 minutes... \n([Y] = 1, [N] = 0):  ");

if run_initiation 
    fprintf("\nThis will take a minute...\n\n");
    binding_indices(mirs_training, gene_training, repress)
end
clearvars run_initiation
%% Obtain windows of specified length for all indices found previously
run_windows = input("Do you want to recalculate the binding windows? " + ...
    "\n([Y] = 1, [N] = 0):  ");

if run_windows
    load('data_sets/feature_data/true_indices.mat');
    fprintf("\nThis might take a minute....\n\n");
    get_gene_windows(gene_training, true_indices, 'nt_windows', 74); %by default, set to 74
end
clearvars run_windows
%% Load Data

load("data_sets/feature_data/true_indices.mat")
load("data_sets/feature_data/reshaped_repress.mat")
load("data_sets/feature_data/reshaped_nt_windows.mat")
load("data_sets/feature_data/reshaped_indices.mat")
load("data_sets/feature_data/true_indices.mat")
load("data_sets/feature_data/nt_windows.mat")
load("data_sets/feature_data/all_indices.mat")
load("data_sets/feature_data/good_repress.mat")
load("data_sets/feature_data/binary_truth.mat")

repress = table2array(repress(:, 2:end))';
%% Feature: Number of Binding Sites Across all regions (Nico)

combined_indices = all_indices(:, :, 1) + all_indices(:, :, 2) + all_indices(:, :, 3); % number of occurances accross all three sequences
M = max(max(combined_indices));
unique_vals = unique(combined_indices);
previewData(combined_indices, 10);

data_pipeline(combined_indices, repress);

%% Feature: Thermodynamics

calc_folding_e = input("\nWould you like to calculate folding " + ...
    "energies?\nThis will take a few minutes..\n [Y]:1, [N]:0\n>>");
if calc_folding_e == 10
    
    %tic
    dim = 0; % change this value depending of sequence region target
    folding_energies = find_folding_energies(windows_reshaped, dim);
    %fold_energy_time = toc;
else
    load('data_sets/feature_data/folding_energies.mat');
    [X, y_obs, y_pred, m, correl] = data_pipeline(folding_energies{1, 3}, reshaped_repress{1, 3});
end
clearvars calc_folding_e

%% Feature: Average Repression in presence and absence of binding site

binding_or_no = all_indices;
temp_repress = repress;
binding_or_no(binding_or_no > 0) = 1;
binding_or_no(binding_or_no ~= 1) = 0;

data_pipeline(binding_or_no(:,:,1), repress);

%% Feature: Nico's CAI (some tweaks to Michal's code)


load("data_sets/feature_data/reshaped_nt_windows.mat")
load("data_sets/feature_data/whole_sequence.mat")
load("data_sets/feature_data/reshaped_repress.mat")
CAI = CAI_generator_nico(windows_reshaped{1, 2}, codon_CAI);
CAI2 = CAI_generator_nico(whole_reshaped{1, 2}, codon_CAI);
data_pipeline(CAI./CAI2, reshaped_repress{1, 2});

%% Feature: Length of miRNA and repression (find average repression levels across each of 74 miRNAs)
mean_repress_miRNA = nanmean(repress(:,2:end)');
mir_length = zeros(1, length(mirs_training));
for i = 1:length(mirs_training(2, :))
    mir_length(i) = strlength(mirs_training(2,i));
end

data_pipeline(mir_length, mean_repress_miRNA)

%% Feature: Conservation

load('data_sets/feature_data/conservations.mat')
load('data_sets/feature_data/reshaped_repress.mat')

data_pipeline(conservation{1, 1}, reshaped_repress{1, 1});

%% Feature: Length of ORF and repression 

mean_repress_gene = nanmean(repress(2:end, :));
orfs = table2array(gene_training(:, 3));
orf_length = zeros(1, length(orfs));
for i = 1:length(orfs)
    orf_length(i) = strlength(orfs(i));
end

data_pipeline(orf_length, mean_repress_gene)

%% Feature: MER Site Distance to closest terminus 

load('data_sets\feature_data\reshaped_indices.mat');
load('data_sets\feature_data\total_lengths.mat');

x = bs_dist_edge();
dist1 = x{1,1};
dist2 = x{1,2};
dist3 = x {1,3};

repress_dist_utr5 = reshaped_indices{1,1};
data_pipeline(dist1, repress_dist_utr5);
repress_dist_orf = reshaped_repress{1,2};
data_pipeline(dist2, repress_dist_orf);
repress_dist_utr3 = reshaped_repress{1,3};
data_pipeline(dist3, repress_dist_utr3);

%% CAI (Michal)
load('data_sets/feature_data/reshaped_nt_windows.mat');
load('data_sets/feature_data/reshaped_repress.mat');
%reshaped_nt_windows.mat is windows_reshaped
Sequences_ORF = windows_reshaped{1,2};
CAI_ORF = CAI_generator(Sequences_ORF,codon_CAI);
Sequences_UTR5 = windows_reshaped{1,1};
CAI_UTR5 = CAI_generator(Sequences_UTR5,codon_CAI);
Sequences_UTR3 = windows_reshaped{1,3};
CAI_UTR3 = CAI_generator(Sequences_UTR3,codon_CAI);

repress_CAI_ORF = reshaped_repress{1,2};
data_pipeline(CAI_ORF, repress_CAI_ORF);
repress_CAI_UTR5 = reshaped_repress{1,1};
data_pipeline(CAI_UTR5, repress_CAI_UTR5);
repress_CAI_UTR3 = reshaped_repress{1,3};
data_pipeline(CAI_UTR3, repress_CAI_UTR3);

%% GC content (Michal)

load('data_sets/feature_data/reshaped_nt_windows.mat');
load('data_sets/feature_data/reshaped_repress.mat');
%reshaped_nt_windows.mat is windows_reshaped
Sequences_ORF = windows_reshaped{1,2};
GC_content_ORF = GC_content_generator(Sequences_ORF);
Sequences_UTR5 = windows_reshaped{1,1};
GC_content_UTR5 = GC_content_generator(Sequences_UTR5);
Sequences_UTR3 = windows_reshaped{1,3};
GC_content_UTR3 = GC_content_generator(Sequences_UTR3);

repress_GC_ORF = reshaped_repress{1,2};
data_pipeline(GC_content_ORF, repress_GC_ORF);
repress_GC_UTR5 = reshaped_repress{1,1};
data_pipeline(GC_content_UTR5, repress_GC_UTR5);
repress_GC_UTR3 = reshaped_repress{1,3};
data_pipeline(GC_content_UTR3, repress_GC_UTR3);


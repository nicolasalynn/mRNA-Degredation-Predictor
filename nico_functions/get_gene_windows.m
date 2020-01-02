%% Returns the 63 nucleotide window around the first index of the seed area

function get_gene_windows(gene_list, indices, file_save_name, window_width, method)
    
    f = waitbar(0, "Calculating Window Energies...");

    %load("data_sets/challenge_data/genes_training.mat");
    conservation_vals = gene_list(:, 5);
    
    indices(isnan(indices)) = 0;
    
    if method == "training"
        file_name_1 = strcat('data_sets/feature_data/', char(file_save_name), '.mat');
        file_name_2 = strcat('data_sets/feature_data/reshaped_', char(file_save_name), '.mat');
        file_name_3 = strcat('data_sets/feature_data/total_lengths.mat');
        file_name_4 = strcat('data_sets/feature_data/whole_sequence.mat');
        file_name_5 = 'data_sets/feature_data/conservations.mat';
    elseif method == "validation"
        file_name_1 = strcat('data_sets/validation_data/', char(file_save_name), '.mat');
        file_name_2 = strcat('data_sets/validation_data/reshaped_', char(file_save_name), '.mat');
        file_name_3 = strcat('data_sets/validation_data/total_lengths.mat');
        file_name_4 = strcat('data_sets/validation_data/whole_sequence.mat');
        file_name_5 = 'data_sets/validation_data/conservations.mat';
    end
        
        
    window = window_width;
    orfs = table2array(gene_list(:, 3));
    utr5s = table2array(gene_list(:, 2));    %
    utr3s = table2array(gene_list(:, 4));    %
    
 
    [num_mirnas, num_genes, dim] = size(indices);
    true_nt_windows = strings(num_mirnas, num_genes, dim);
    total_lengths = zeros(num_mirnas, num_genes, dim);
    whole_sequence = strings(num_mirnas, num_genes, dim);
    average_conservation = zeros(num_mirnas, num_genes, dim);

        for gene = 1:num_genes
            waitbar(gene/num_genes, f, "Looping through indices...")


            orf = cell2mat(orfs(gene));
            utr5 = cell2mat(utr5s(gene));   
            utr3 = cell2mat(utr3s(gene));   


            for mirna = 1:num_mirnas

                index_val_utr5 = indices(mirna, gene, 1);
                index_val_orf = indices(mirna, gene, 2);
                index_val_utr3 = indices(mirna, gene, 3); 


                utr5_length = strlength(utr5);
                orf_length = strlength(orf);
                utr3_length = strlength(utr3);
                conservation_vector = cell2mat(conservation_vals{gene, 1})';
                
                if (index_val_utr5 ~= 0)
                    total_lengths(mirna, gene, 1) = strlength(utr5);
                    whole_sequence(mirna, gene, 1) = utr5;
                    
                    if strlength(utr5) < window
                        true_nt_windows(mirna, gene, 1) = utr5;
                        average_conservation(mirna, gene, 1) = mean(conservation_vector(1:utr5_length));
                    elseif (index_val_utr5 <= window/2)
                        true_nt_windows(mirna, gene, 1) = utr5(1:window);
                        average_conservation(mirna, gene, 1) = mean(conservation_vector(1:utr5_length));
                    elseif (index_val_utr5 > strlength(utr5) - window/2)
                        true_nt_windows(mirna, gene, 1) = utr5(length(utr5)-window:end);
                        average_conservation(mirna, gene, 1) = mean(conservation_vector(utr5_length - window:utr5_length));
                    else
                        true_nt_windows(mirna, gene, 1) = utr5(index_val_utr5 - window/2:index_val_utr5 + window/2);
                        average_conservation(mirna, gene, 1) = mean(conservation_vector(index_val_utr5 - window/2:index_val_utr5 + window/2));
                    end
                else
                    true_nt_windows(mirna, gene, 1) = NaN;
                    whole_sequence(mirna, gene, 1) = NaN;
                    average_conservation(mirna, gene, 1) = NaN;

                end
                
                
                if (index_val_orf ~= 0)
                    total_lengths(mirna, gene, 2) = strlength(orf);
                    whole_sequence(mirna, gene, 2) = orf;

                    if strlength(orf) < window
                        true_nt_windows(mirna, gene, 2) = orf;
                        average_conservation(mirna, gene, 2) = mean(conservation_vector(utr5_length:utr5_length + orf_length));
                    elseif (index_val_orf <= window/2)
                        true_nt_windows(mirna, gene, 2) = orf(1:window);
                        average_conservation(mirna, gene, 2) = mean(conservation_vector(utr5_length:utr5_length + orf_length));
                    elseif (index_val_orf > strlength(orf) - window/2)
                        true_nt_windows(mirna, gene, 2) = orf(length(orf)-window:end);
                        average_conservation(mirna, gene, 2) = mean(conservation_vector(utr5_length + orf_length - window:utr5_length + orf_length));
                    else
                        true_nt_windows(mirna, gene, 2) = orf(index_val_orf - window/2:index_val_orf + window/2);
                        average_conservation(mirna, gene, 2) = mean(conservation_vector(utr5_length + index_val_orf - window/2:utr5_length + index_val_orf + window/2));
                    end
                else
                    true_nt_windows(mirna, gene, 2) = NaN;                    
                    whole_sequence(mirna, gene, 2) = NaN;
                    average_conservation(mirna, gene, 2) = NaN;

                end
                    
                    
                if (index_val_utr3~= 0)
                    total_lengths(mirna, gene, 3) = strlength(utr3);
                    whole_sequence(mirna, gene, 3) = utr3;

                    if strlength(utr3) < window
                        true_nt_windows(mirna, gene, 3) = utr3;
                        average_conservation(mirna, gene, 3) = mean(conservation_vector(utr5_length + orf_length:utr5_length + orf_length + utr3_length));
                    elseif (index_val_utr3 <= window/2)
                        true_nt_windows(mirna, gene, 3) = utr3(1:window);
                        average_conservation(mirna, gene, 3) = mean(conservation_vector(utr5_length + orf_length:utr5_length + orf_length + utr3_length));
                    elseif (index_val_utr3 > strlength(utr3) - window/2)
                        true_nt_windows(mirna, gene, 3) = utr3(length(utr3)-window:end);
                        average_conservation(mirna, gene, 3) = mean(conservation_vector(utr5_length + orf_length + utr3_length - window:utr5_length + orf_length + utr3_length));                        
                    else
                        true_nt_windows(mirna, gene, 3) = utr3(index_val_utr3 - window/2:index_val_utr3 + window/2);
                        average_conservation(mirna, gene, 3) = mean(conservation_vector(utr5_length + orf_length + index_val_utr3 - window/2:utr5_length + orf_length + index_val_utr3 + window/2));                   
                    end
                else
                    true_nt_windows(mirna, gene, 3) = NaN;
                    whole_sequence(mirna, gene, 3) = NaN;
                    average_conservation(mirna, gene, 3) = NaN;
                end
                    
                    
                          
            end
        end
    
    
    windows_reshaped = reshape_nico(true_nt_windows, "str");
    total_lengths(total_lengths == 0) = NaN;
    lengths_reshaped = reshape_nico(total_lengths, "num");
    whole_reshaped = reshape_nico(whole_sequence, "str");
    %average_conservation(average_conservation == 0) = NaN;
    conservation = reshape_nico(average_conservation, "num");
    
    
    clear binding_indices
    
    
    save(file_name_1, 'true_nt_windows')
    save(file_name_2, 'windows_reshaped')
    save(file_name_3, 'lengths_reshaped')
    save(file_name_4, 'whole_reshaped')
    save(file_name_5, 'conservation');
    
    close(f)

end

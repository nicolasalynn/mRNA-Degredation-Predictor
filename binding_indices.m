%% Will return the first occurance of particular miRNA seed complement in each gene
%{
    This function will return a matrix with the first occurance of a
    bidning side in each of the 3 segments of code for the gene, all in a
    3D array. Additionally, this function will return the number of
    occurances of binding sites in each region. This infomation may prove
    useful as the number of bidning sites may increase ease of binding and
    increase repression.

    NEEDS TESTING: new modifications include keeping count of the number of
    binding sides in each region as well as generating 2 new dimesions to
    the saved matrix that look for the first binding side in the UTRs.
%}


function binding_indices(mirs_training, gene_training)
    first_indices = zeros(length(mirs_training), size(gene_training, 1), 3); %first_inidices: 74 rows, 3947 columns
    all_indices = zeros(length(mirs_training), size(gene_training, 1), 3);    
    orfs = table2array(gene_training(:, 3));
    utr5 = table2array(gene_training(:,2));
    utr3 = table2array(gene_training(:,4));

    for i = 1:length(mirs_training)                 % i = 1:74
        mirna_seq = char(mirs_training(2, i));      % mirna_seq is the sequence of the miRNA
        seed = mirna_seq(2:8);                      % this should be the seed (2:8) of the miRNA
        mer_site = seqrcomplement(seed);            % finding the reverse complement of the seed
        mer_site = strcat(mer_site,'A');            % adding the a is so that it follows mer78 

        for j = 1:size(gene_training, 1)            % j = 1:3947
            
            str_of_utr5 = dna2rna(string(utr5{j}));
            str_of_orf = dna2rna(string(orfs{j}));          
            str_of_utr3 = dna2rna(string(utr3{j}));
            
            temp_utr5 = regexp(str_of_utr5, mer_site);
            temp_orf = regexp(str_of_orf, mer_site);            %finding indices in each segment
            temp_utr3 = regexp(str_of_utr3, mer_site);
            
            all_indices(i, j, 1) = length(temp_utr5);
            all_indices(i, j, 2) = length(temp_orf);
            all_indices(i, j, 3) = length(temp_utr3);

            if isempty(temp_utr5)
                first_indices(i, j, 1) = 0;
            else
                first_indices(i, j, 1) = temp_utr5(1);
            end

            
            if isempty(temp_orf)
                first_indices(i, j, 2) = 0;
            else
                first_indices(i, j, 2) = temp_orf(1);             
            end
            
            
            if isempty(temp_utr3)
                first_indices(i, j, 3) = 0;
            else
                first_indices(i, j, 3) = temp_utr3(1);
            end
            
        end

    end

    save('data_sets/feature_data/binding_indices.mat', 'first_indices')
    save('data_sets/feature_data/all_indices.mat', 'all_indices')
end


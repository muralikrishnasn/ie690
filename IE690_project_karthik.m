%% CODE for IE 690 Project!
% Written by Sriram Karthik Badam, Deok Gun Park
% based on the code examples provided in Chalearn 

clear;
clc;
    
if ~exist('this_dir')
    this_dir=pwd;
end
 
data_path   = [this_dir '/Examples/'];    % Path to the sample data.
data_dir    = [data_path '/devel/'];    % Path to the sample data.
code_dir    = this_dir; % Path to the code.
   
% Add the path to the function library
warning off; 
addpath(genpath(code_dir)); 
warning on;

%% ================== BEGIN LOADING DATA ======================================

%Choose an example
example_num=input('Movie example num [1, 2, 3 or 4 for the entire training dataset or 5 for testing the validation data]: ');
training = 0;
validation = 0;

% For each movie, we fetched the labels from train.csv and test.csv
if example_num==1
    batch_num=1;  movie_num=19; 
    train_labels=[10 7 4 2 8 1 6 9 3 5];
    test_labels=[10 2 3 3];
    data_name=sprintf('devel%02d', batch_num);
    % Load M and K movies... (fps is the number of frames per seconds)
    fprintf('Loading movie, please wait...');
    [K0, fps]=read_movie([data_dir '/' data_name  '_K_' num2str(movie_num) '.avi']); 
    [M0, fps]=read_movie([data_dir '/' data_name  '_M_' num2str(movie_num) '.avi']); 
    fprintf(' Done!\n\n');
    movie_features = getEdgeFeatures2(K0);

elseif example_num==2
	batch_num=3;  movie_num=16; 
    train_labels=[5 1 4 6 8 7 2 3];
    test_labels=[6 2 1 3];
    data_name=sprintf('devel%02d', batch_num);
    % Load M and K movies... (fps is the number of frames per seconds)
    fprintf('Loading movie, please wait...');
    [K0, fps]=read_movie([data_dir '/' data_name  '_K_' num2str(movie_num) '.avi']); 
    [M0, fps]=read_movie([data_dir '/' data_name  '_M_' num2str(movie_num) '.avi']); 
    fprintf(' Done!\n\n');
    movie_features = getEdgeFeatures2(K0);

elseif example_num==3
    batch_num=15;  movie_num=24; 
    train_labels=[4 3 1 6 5 7 2 8];
    test_labels=[4];
    data_name=sprintf('devel%02d', batch_num); 
    % Load M and K movies... (fps is the number of frames per seconds)
    fprintf('Loading movie, please wait...');
    [K0, fps]=read_movie([data_dir '/' data_name  '_K_' num2str(movie_num) '.avi']); 
    [M0, fps]=read_movie([data_dir '/' data_name  '_M_' num2str(movie_num) '.avi']); 
    fprintf(' Done!\n\n');
    movie_features = getEdgeFeatures2(K0);

elseif example_num==4
    data_path   = ['devel-1-20_valid-1-20'];    % Path to the sample data.
    data_dir    = [data_path '/devel'];    % Path to the sample data.
    code_dir    = this_dir;
    training = 1;
    
elseif example_num==5
    %Validation set
    validation = 1;
    data_path   = ['devel-1-20_valid-1-20'];    % Path to the sample data.
    data_dir    = [data_path '/devel'];    % Path to the sample data.
    code_dir    = this_dir;
end

%% ======================= get features and build HMM =======================

all_features = [];

edgeX = [];
edgeY = [];
if training == 1
    for i = 1:1
        if i < 10
            data_dir = [data_path '/devel0' num2str(i) '/'];
        else 
            data_dir = [data_path '/devel' num2str(i) '/'];
        end
        for j = 1:10
            data_name=sprintf('K_%d', j); 
            % Load M and K movies... (fps is the number of frames per seconds)
            fprintf('Loading movie, please wait... %s\n', [data_dir data_name '.avi']);
            [K0, fps]=read_movie([data_dir data_name '.avi']); 
            %[M0, fps]=read_movie([data_dir '/' data_name  '_M_' num2str(movie_num) '.avi']); 
            
            [movie_features, edge1, edge2] = getEdgeFeatures2(K0);
            edgeX = [edgeX; edge1];
            edgeY = [edgeY; edge2];
            all_features = [all_features; struct('gesture', movie_features)];
            fprintf(' Done!\n\n');
              
            
        end
    end

% find variance of edgeX, edgeY
sigmaX = var(edgeX./120)^0.5;
sigmaY = var(edgeY./180)^0.5;    
end



%% ======================= generative model =================================

if validation == 1
    load('features1.mat');
    data_dir = [data_path '/devel01/'];
    data_name=sprintf('K_%d', 14); 
    data_name2=sprintf('M_%d', 14); 
    
    % Load M and K movies... (fps is the number of frames per seconds)
    fprintf('Loading movie, please wait... %s\n', [data_dir data_name '.avi']);
    [K0, fps]=read_movie([data_dir data_name '.avi']); 
    [M0, fps]=read_movie([data_dir data_name2 '.avi']); 
    
    K0 = K0(41:89);      
    %get the features in the testing set
    movie_features = getEdgeFeatures2(K0);
    fprintf(' Done!\n\n');
    
    obsLik = [];
    
    %the index of the gesture and frame that the test frame corresponds to. 
    training_gesture_index = zeros(length(movie_features));
    training_frame_index = zeros(length(movie_features));    
    global_prob = 1;
    max_global = -Inf;
    
    for i= 1:length(all_features)
       B = zeros(length(all_features(i).gesture) ,length(movie_features));
       fprintf('Gesture %d\n', i);
             
       for frame=1:length(movie_features)
        %max_global = -Inf;

            T = movie_features(frame).frame;
            
            for j=1:length(all_features(i).gesture)                
                % edge points in a frame
                P = all_features(i).gesture(j).frame;
               
                if size(P, 1) > 0 && size(T, 1) > 0
                    
                    %An alternative sort to speed up things!
                    [D, id] = pdist2(P, T, 'euclidean','Smallest', 1);
                    prob = -(((P(id, 1) - T(:, 1))./120).^2)/(2*sigmaX^2)-(((P(id, 2) - T(:,2))./180).^2)/(2*sigmaY^2);
                    local_prob = sum(prob);

                    % update B -- the emission matrix
                    B(j, frame) = local_prob;
                    
                elseif size(P, 1) == 0 && size(T, 1) == 0 
                    B(j, frame) = 0;
                
                elseif size(P, 1) == 0 && size(T, 1) ~= 0
                    B(j, frame) = -40;
                
                elseif size(P, 1) ~= 0 && size(T, 1) == 0
                    B(j, frame) = -40;
                end                
            end
	   end
	 
       obsLik = [obsLik; struct('B', B)];
    end

    
% Temporal Segment gesture
    [time, distance] = temporal_segment(K0, M0);
    
    endtime = time(size(time,1), 2);
    
    if (length(movie_features) - endtime > 30)
        time(size(time, 1)+1) = [endTime+1 length(movie_features)];
    end
    
    if size(time,1) == 0
        time = [1, length(movie_features)]
    end
    factor = 10^4;
     mean1 = zeros(10,1);       
     for i=1:10
          mean1(i) = mean(mean(obsLik(i).B));
     end
     if ceil(mean(mean1)/10^4) <= -5
         factor = 10^5;
     end
    
    pathList = [];
    classify = [];
    % Classify each segment using HMM
    for gest = 1:size(time,1) 
        list = [];
        
        
        %for all gestures in training set
        for i= 1:length(all_features)
            
            i
            numFrame = length(all_features(i).gesture);
            numFrameTest = length(movie_features); 
            prior = 1/numFrameTest * ones(numFrame,1);
            transmat = makeTransmat(numFrame, 0.79, 0.01, 0.2, 1);
            
            b =  obsLik(i).B(:,time(gest, 1):time(gest, 2));
            
            [path] = viterbi_path(prior, transmat, exp(b/factor))
            
             probabilities = [];
             probability = b(path(1), 1);
             gesture = 0;
            for frame=2:(length(path))
                 probability = probability + b(path(frame), frame) + log(transmat(path(frame-1), path(frame)));   
            end
            probabilities = [probabilities; probability];
            
            
             probabilities
             if (length(probabilities) > 0)
                [value, index] = max(probabilities);
                list = [list; [value, i]];
            end
            
        end

        %classify 
        [value, index] = max(list(:, 1));
        
        classify = [classify; list(index, 2)];
    end
    
	classify
    	
end




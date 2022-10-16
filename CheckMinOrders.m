function [Loops,Edges] = CheckMinOrders(Loops,Edges,BConds)
% CHECKMINORDERS checks if the initial orders of the domain and Dirichlet 
% boundaries meet the positive kinematic indeterminacy requirement. The 
% kinematic indeterminacy condition is covered in Section 3.4.2 of 
% reference [2], section 4.5.2 of reference [3], and section 3.6 of 
% reference [4]. If the criterion is not satisfied the refinement order is 
% increased in the domain of the element.
%
% CheckMinDegrees is called by MAIN*** 
% Input:
%   Loops, Edges data structures
% Output/Returns to MAIN***
%   Loops, Edges data structures with updated refinement orders (if required)
%
% BIBLIOGRAPHY
% 1. FreeHyTE Page - https://sites.google.com/site/ionutdmoldovan/freehyte
% 2. Moldovan ID, Cismasiu I - FreeHyTE: theoretical bases and developer’s 
% manual, https://drive.google.com/file/d/0BxuR3pKS2hNHTzB2N2Q4cXZKcGc/view
% 3. FreeHyTE Heat HTTE User's Manual - 
%    https://drive.google.com/drive/folders/0BxuR3pKS2hNHaFhiSjZHOE9TMzg
% 4. Barbosa C - Algoritmo 'p'-adaptativos com indicadores de erros globais
% e locais para problemas de elasticidade, MSc Thesis, Universidade Nova de Lisboa,
% 2022 (in Portuguese).


%Inicialization
Loops.dim = zeros(length(Loops.area),5);
Edges.dim = zeros(length(Edges.type),2);

% Calculating the total dimension of the basis for all elements
for i = 1:length(Loops.area)
    % K11 block
    Loops.dim(i,1) = Loops.order(i);
    % K22 block
    Loops.dim(i,2) = Loops.order(i);
    % K33 block
    % The lowest order term of K33 is null and not included in the basis.
    % Its dimension is thus inferior to the other blocks.
    Loops.dim(i,3) = Loops.order(i)-1;
    % K44 block
    Loops.dim(i,4) = Loops.order(i);
    % K55 (= 0) block
    % Three rigid body modes
    Loops.dim(i,5) = 3;  
end

%Calculates the total dimension of the basis for every essential boundary
for i = 1:length(Edges.type)
    if strcmpi(Edges.type(i),'D')  % if the egde is Dirichet (or interior)
        % If there's no right element, it's an exterior Dirichlet boundary.
        % Exterior Dirichlet boundaries may have applied displacements in
        % one direction (i.e. normal or tangential) or in both. 
        if(~Edges.lright(i))  
            % If any of the terms in BConds.Dirichlet{i,1} is different 
            % from NaN, it means that displacements are applied in the
            % boundary normal direction. Then, space is stored for the
            % insertion of the boundary matrix.
            if any(~isnan(BConds.Dirichlet{i,1})) 
                Edges.dim(i,1) = Edges.order(i,1)+1; 
            end
            % If any of the terms in BConds.Dirichlet{i,2} is different 
            % from NaN, it means that displacements are applied in the
            % boundary tangential direction. Then, space is stored for the
            % insertion of the boundary matrix.            
            if any(~isnan(BConds.Dirichlet{i,2}))
                Edges.dim(i,2) = Edges.order(i,2)+1; %ALTERADO POR CESAR
            end
        else   % Interior boundaries have boundary matrices in both directions.
                Edges.dim(i,1) = Edges.order(i,1)+1; 
                Edges.dim(i,2) = Edges.order(i,2)+1; 
        end
    end
end

%Computes the indeterminacy number Beta for each element
Beta = zeros(length(Loops.area),1);
for i=1:length(Loops.area)
    Beta(i) = sum(Loops.dim(i,:)) - sum(sum(Edges.dim(Loops.edges(i,:),:)),2);
end

%Increase the order of the element basis if Beta <= 0
for i=1:length(Beta)
    while Beta(i)<=0
        Loops.order(i)=Loops.order(i)+1;
        % recompute the dimension of the element's basis
        % K11 block
        Loops.dim(i,1) = Loops.order(i);
        % K22 block
        Loops.dim(i,2) = Loops.order(i);
        % K33 block
        % The lowest order term of K33 is null and not included in the basis.
        % Its dimension is thus inferior to the other blocks.
        Loops.dim(i,3) = Loops.order(i)-1;
        % K44 block
        Loops.dim(i,4) = Loops.order(i);
        % K55 (= 0) block
        % Three rigid body modes
        Loops.dim(i,5) = 3;
        % recomputes the kinematic indeterminacy number, Beta
        Beta(i) = sum(Loops.dim(i,:)) - sum(sum(Edges.dim(Loops.edges(i,:),:)),2);
    end
end
end

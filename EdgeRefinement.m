function [Edges,Loops,List] = EdgeRefinement(Edges,...
    Loops,BConds,Sc,LHS0,Energy0,abscissa,weight,X,List,Dim,index,...
    iteration,EnergyIteration,SelectionCriterion,a,listposition)
% EDGEREFINEMENT computes the values of the global and local selection
% criteria for the essential boundary 'index'. It assumes that the basis
% is enriched independently by adding one single function to it. 
% The values of the selection criteria are stored in the List.Edge 
% matrix, and the edges are ranked according to the selection criterion
% chosen by the user.
%
% EdgeRefinement is called by MAIN*** when the p-adaptive processes is 
% launched.
% Input data:
% * the Edges, Loops, BConds and List data structures; 
% * the matrix of coefficients before the refinement, LSH0;
% * the thermal energy before the refinement, Energy0; 
% * the solution vector X; 
% * the dimension of the solving system before the refinement, Dim;
% * the boundary to be refined, index;
% * the current iteration counter, iteration; 
% * the list with the thermal energy of all previous iteration, EnergyIteration;
% * the SelectionCriterion selected by the user in the GUI;
% * the Gauss-Legendre integration parameters abscissa and weights. 
% Output/Returns to MAIN*** :
% the List structure with the List.Edges updated (edges that were selected 
% for refinement), and the updated Loops and Egdes structures.
% 
%
% BIBLIOGRAPHY
% 1. FreeHyTE Page - https://sites.google.com/site/ionutdmoldovan/freehyte
% 2. Moldovan ID, Cismasiu I - FreeHyTE: theoretical bases and developer�s 
% manual, https://drive.google.com/file/d/0BxuR3pKS2hNHTzB2N2Q4cXZKcGc/view
% 3. FreeHyTE Heat HTTE User's Manual - 
%    https://drive.google.com/drive/folders/0BxuR3pKS2hNHaFhiSjZHOE9TMzg
% 4. Barbosa C - Algoritmo 'p'-adaptativos com indicadores de erros globais
% e locais para problemas de elasticidade, MSc Thesis, Universidade Nova de Lisboa,
% 2022 (in Portuguese).
%
% Boundary refinement criteria are global, monitoring the solution energy 
% variation, or local, monitoring the boundary balance residual.
% The solution energy variation criterion selects for refinement the 
% boundary that causes the largest relative variation of the solution
% energy.
% What is typical for the hybrid-Trefftz formulations is that they not 
% produce "kinematically" or "statically" admissible solutions and the 
% monotonous convergence of the energy does not generally occur, meaning 
% that the solution energy oscillates in the vicinity of the exact solution 
% as it converges. 
% In alternative, the boundary balance residual criterion selects for 
% refinement the boundary where adding one shape function would cause the 
% largest improvement of the displacement balance of all essential
% boundaries of the mesh.
% The definition and computation of the selection criteria are covered in
% reference [2] (section 6.3), reference [3] (section 4.3), and reference
% [4] (section 4.6.1).

% Identify the refined edge
% ii=index;

% Create the Abar matrix and intialize with zero. The refinement of the 
% edge adds one degree of freedom to the boundary, so the dimension of the 
% Abar matrix is 'Dim+1'. 
Abar=zeros(Dim+1,Dim+1);    

% Insert the "old" A matrix into the new Abar as only the new terms 
% associated with the new dof need to be computed.
Abar(1:Dim,1:Dim)=LHS0;

% Identify the refined edge
ii=index;

% Update edges order and dimension of the B matrix
Edges.order(ii,a)=Edges.order(ii,a)+1; 
Edges.dim(ii,a)=Edges.dim(ii,a)+1;

% Abar is the old LHS matrix (LHS0) with the new B* corresponding to the
% newly refined boundaries (equation 5.7 of reference [4])
Abar = B1bar(Edges, Loops, Abar, abscissa, weight, Dim, ii,a);
Abar = B2bar(Edges, Loops, Abar, abscissa, weight, Dim, ii,a);
Abar = B3bar(Edges, Loops, Abar, abscissa, weight, Dim, ii,a);
Abar = B4bar(Edges, Loops, Abar, abscissa, weight, Dim, ii,a);
Abar = B5bar(Edges, Loops, Abar, abscissa, weight, Dim, ii,a);

% Perform scaling of the last line & column in the Abar matrix
Abar(end,:) = [Sc;1]' .* Abar(end,:);
Abar(:,end) = [Sc;1] .* Abar(:,end);

% Computes u_gamma_tilde defined by equations 4.4 of 
% reference [4]. If the edge is incremented with a single dof, u_gamma_tilde
% is scalar, but the routine is constructed to accommodate
% their possible extensions to vectorial quantities.
Ubar = Ubari(Edges, BConds, abscissa, weight, ii, a);
% the last term of the free vector in system (5.2)

% Reset edge's order and dimension of the B matrix for current edge
Edges.order(ii,a)=Edges.order(ii,a)-1;
Edges.dim(ii,a)=Edges.dim(ii,a)-1;

% Compute xdot according to expression (4.10) of reference [4]. If the
% LHS0 matrix is ill-conditioned, the Moore-Penrose pseudoinverse is used.
if (rcond(LHS0)<eps)
    xdot = -pinv(LHS0)*Abar(1:Dim,Dim+1);
else
    xdot = -LHS0\(Abar(1:Dim,Dim+1));
end

% Compute the absolute displacement balance improvement on the current edge, 
% i.e. the last term of the free vector os system (4.6) of reference [4].
ErrorEdge = (Ubar-Abar(Dim+1,1:Edges.Edgeinsert-1)*...
         X(1:Edges.Edgeinsert-1));     
     
% Compute Ybar according to expression 4.14 of reference [4]
if abs(ErrorEdge) 
    Ybar = ErrorEdge/(Abar(Dim+1,1:Dim)*xdot);
    % Error edge norm is normalized to the length of the edge
    L = (sqrt(Edges.parametric(ii,3)^2 + Edges.parametric(ii,4)^2));
    ErrorEdgeNorm = abs(ErrorEdge)/L;
else
    % if ErrorEdge = 0, the added dof brings no change to the solution
    List.Edge(listposition,1)=ii;
    List.Edge(listposition,2)=a;
    List.Edge(listposition,3)=0;
    List.Edge(listposition,4)=0;
    return;
end

% Compute Delta X "solution variation" according to equation (3.12) of 
% reference [4]
DeltaX = xdot*Ybar;

% Compute the solution energy, according to equation (3.52) of reference
% [4] (the constant part is excluded)
Energy = (1/2)*(X(1:Edges.Edgeinsert-1)+DeltaX(1:Edges.Edgeinsert-1))'*...
         Abar(1:Edges.Edgeinsert-1,1:Edges.Edgeinsert-1)*...
         (X(1:Edges.Edgeinsert-1)+DeltaX(1:Edges.Edgeinsert-1));
     

% Compute the energy difference, 'DeltaU'
% If it's the first iteration, the energy from the initial run is used
if iteration == 1 
    DeltaU = abs(Energy0-Energy);
elseif iteration > 1
    DeltaU = abs(EnergyIteration(iteration-1)-Energy);
end
% Filling up the List.Edge matrix with the solution energy cariation and
% boundary balance residual.
List.Edge(listposition,1)=ii;
List.Edge(listposition,2)=a;
List.Edge(listposition,3)=ErrorEdgeNorm;
List.Edge(listposition,4)=DeltaU;

% Sorting the list according to the selection criterion in descending order
[List.Edge(:,SelectionCriterion),indice]=...
    sort(List.Edge(:,SelectionCriterion),'descend'); 

% Rewritting the reminder of the list according to the order determined above
for iii=1:4
    if iii ~= SelectionCriterion
        List.Edge(:,iii)=List.Edge(indice(:),iii);
    end

end

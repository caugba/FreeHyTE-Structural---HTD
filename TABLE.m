function TABLE(GDL,Beta,...
    EnergyIt,LoopsOrderIt,EdgesOrderIt,...
    RefinedEdgesIt,RefinedLoopsIt,CndNoIt,TargetErrorNorm,...
    SelectionTol,MaxOutlierIter,SelectionCriterion,thresh,MinIter,AvgNVal,...
    StoppingCriterion) 
 
TableRefinedEdgesIt=RefinedEdgesIt;
Data=cell(length(GDL)+9,11);
for i= 1:length(GDL)
    [TableRefinedEdgesIt{i,:}(:,1),indice]=sort(TableRefinedEdgesIt{i,:}(:,1),'ascend');
    TableRefinedEdgesIt{i,:}(:,2)=TableRefinedEdgesIt{i,:}(indice(:),2);
    for j=1:size(TableRefinedEdgesIt{i,:},1)
        if TableRefinedEdgesIt{i,:}(j,2)==1
            Data{i,6}=strcat(Data{i,6},num2str(TableRefinedEdgesIt{i,:}(j,1)),{' '});
        else
            Data{i,7}=strcat(Data{i,7},num2str(TableRefinedEdgesIt{i,:}(j,1)),{' '});
        end
    end
    Data{i,6}=char(Data{i,6});
    Data{i,7}=char(Data{i,7});
    Data{i,1}=i;
    Data{i,2}=num2str(GDL(i));
    Data{i,3}=num2str(Beta(i,:));
    Data{i,4}=num2str(RefinedLoopsIt{i,:});
    Data{i,5}=num2str(LoopsOrderIt(:,i)');
    Data{i,8}=num2str(EdgesOrderIt(:,1,i)');
    Data{i,9}=num2str(EdgesOrderIt(:,2,i)');
    Data{i,10}=num2str(EnergyIt(i));
    Data{i,11}=num2str(CndNoIt(i));
end
Data{i+2,1}='TargetErrorNorm=';
Data{i+3,1}='SelectionTol=';
Data{i+4,1}='MaxOutlierIter=';
Data{i+5,1}='SelectionCriterion=';
Data{i+6,1}='thresh=';
Data{i+7,1}='MinIter=';
Data{i+8,1}='AvgNVal=';
Data{i+9,1}='StoppingCriterion=';
Data{i+2,2}=num2str(TargetErrorNorm);
Data{i+3,2}=num2str(SelectionTol);
Data{i+4,2}=num2str(MaxOutlierIter);
Data{i+5,2}=num2str(SelectionCriterion);
Data{i+6,2}=num2str(thresh);
Data{i+7,2}=num2str(MinIter);
Data{i+8,2}=num2str(AvgNVal);
Data{i+9,2}=num2str(StoppingCriterion);
cnames={'Iteration','DOF','Beta','Refined Loops','Loops Order',...
    'Refined Edge Normal Dir','Refined Edge Tangencial Dir', ...
    'Edges Order Normal Dir', 'Edges Order Tangencial Dir','Energy',...
    'Condition Number'};
maxLen = zeros(1,11);
for i=1:11
    for j=1:length(GDL)
        len = length(Data{j,i});
        if (len>maxLen(i))
            maxLen(i) = len;
        end
    end
end
cellMaxLen = num2cell(ceil(maxLen*4.2));
for i=1:11
    if cellMaxLen{i}<length(cnames{i})
       cellMaxLen{i}=length(cnames{i})+10;
    end
end
f = figure('Position',[50 100 ...
    70+50+cellMaxLen{3}+20+100+cellMaxLen{5}+20+100+cellMaxLen{7}+70+700 450],...
    'color','w');
set(f,'name','Table of iterations info','numbertitle','off');
table = uitable('Parent',f,'units','pixels');
set(table,'Data',Data,'ColumnName',cnames,...
    'RowName',[],'Position',[10 25 70+50+cellMaxLen{3}+20+100+cellMaxLen{5}+20+100+cellMaxLen{7}+70+60+1000 400],...
    'ColumnWidth',{70 50 cellMaxLen{3}+20 100 cellMaxLen{5}+20 cellMaxLen{6} cellMaxLen{7} cellMaxLen{8} cellMaxLen{9} 70});
CombData=[cnames;Data];
xlswrite('FileName.xlsx',CombData);
%set(f,'menubar','none');
%writetable(c,'test.xlsx','Sheet',1);
end
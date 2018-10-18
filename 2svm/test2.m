%------------������----------------
clear;
close all;
C = 10;  %�ɱ�Լ������
kertype = 'rbf';  %rbf��˹��
 
%��------����׼��5*10����ÿ������20���㣬��1000����
x1=[];
x3=[];
for i=0:1:9
    for j=0:1:4
        b=j+rand(20,1);%�������20����
        c=i+rand(20,1);      
        x0=[x1;b];
        x2=[x3;c];
        x1=x0;  %�����x1�����е�ĺ�����
        x3=x2;  %x3�����е��������,(x1,x3)
    end
end
 
y0=[];%�����������е�ı��
y1 = ones(20,1); %20��+1���
y2 = -ones(20,1);%20��-1���
for k=0:1:24    %ѭ����ֵ��ʹ��5*10���������ڵĸ��ӱ�Ƕ���һ��
        y0=[y0;y1];
        y0=[y0;y2];
end
 
 
x1=x1.'
x3=x3.'  %�ǵ�ת��һ��Ŷ
figure;  %����һ��������ʾͼ�������һ�����ڶ���
 
for m=1:1:25
    plot(x1(1,(1+20*(2*m-2)):(20*(2*m-1))),...
        x3(1,(1+20*(2*m-2)):(20*(2*m-1))),'k.');  %��ͼ
    hold on; 
    plot(x1(1,(1+20*(2*m-1)):(20*(2*m))),...
        x3(1,(1+20*(2*m-1)):(20*(2*m))),'b+');  %��ͼ
    hold on;    %��ͬһ��figure�л�����ͼʱ���ô˾�
end
%axis([0 5 0 10]);  %���������᷶Χ
 
%��-------------ѵ������
X = [x1;x3];        %ѵ������2*n����nΪ����������dΪ������������
Y = y0.';        %ѵ��Ŀ��1*n����nΪ����������ֵΪ+1��-1
svm = svmTrain(X,Y,kertype,C);  %ѵ������
%%%��֧�����������,��֧���������Ĳ��ԣ���ʱ��ͨ����kernel�����������޸�
for i=1:1:svm.svnum
    if svm.Ysv(1,i)==1
        plot(svm.Xsv(1,i),svm.Xsv(2,i),'mo');%һ��֧�������÷�ɫȦס
    else
        plot(svm.Xsv(1,i),svm.Xsv(2,i),'ko');%��һ��֧��������ɫȦ
    end
end
%plot(svm.Xsv(1,:),svm.Xsv(2,:),'ro');
 
%��-------------����
[x1,x2] = meshgrid(0:0.05:5,0:0.05:10);  %���ֵ�����ŵȸ����ڼ��˼���Χ������
[rows,cols] = size(x1);  
nt = rows*cols;                  
Xt = [reshape(x1,1,nt);reshape(x2,1,nt)];
%ǰ���reshape(x1,1,nt)�ǽ�x1ת��1*��rows*cols���ľ�������Xt��2*��rows*cols���ľ���
%reshape�������µ���������С��С�ά��
y3 = ones(1,floor(nt/2));
y4 = -ones(1,floor(nt/2)+1);
Yt = [y3,y4];
 
result = svmTest(svm, Xt, Yt, kertype);
 
%��--------------�����ߵĵȸ���ͼ
Yd = reshape(result.Y,rows,cols);
contour(x1,x2,Yd,3); %��������ˮƽ�ĵȸ���
 
title('5*10���ݷ���');   
x1=xlabel('X��');  
x2=ylabel('Y��'); 
 
 
 
%-----------ѵ�������ĺ���svmTrain---------
function svm = svmTrain(X,Y,kertype,C)
 
% Options�����������㷨��ѡ�������������optimset�޲�ʱ������һ��ѡ��ṹ�����ֶ�ΪĬ��ֵ��ѡ��
options = optimset;    
options.LargeScale = 'off';%LargeScaleָ���ģ������off��ʾ�ڹ�ģ����ģʽ�ر�
options.Display = 'off';    %��ʾ�����
 
%���ι滮��������⣬����������help quadprog�鿴����
n = length(Y);  %����Y�ά��
H = (Y'*Y).*kernel(X,X,kertype);    
f = -ones(n,1); %fΪ1*n��-1,f�൱��Quadprog�����е�c
A = [];
b = [];
Aeq = Y; %�൱��Quadprog�����е�A1,b1
beq = 0;
lb = zeros(n,1); %�൱��Quadprog�����е�LB��UB
ub = C*ones(n,1);
a0 = zeros(n,1);  % a0�ǽ�ĳ�ʼ����ֵ
[a,fval,eXitflag,output,lambda]  = quadprog(H,f,A,b,Aeq,beq,lb,ub,a0,options);
%a���������������Ľ�
%fval��Ŀ�꺯���ڽ�a����ֵ
%eXitflag>0,����������ڽ�x��=0�����ļ���ﵽ����������<0�������޿��н⣬���������ʧ��
%output����������е�ĳЩ��Ϣ
%lambdaΪ�ڽ�a����ֵLagrange����
 
epsilon = 1e-8;  
 %0<a<a(max)����ΪxΪ֧������,find����һ����������X��ÿ������Ԫ�ص����������������� 
sv_label = find(abs(a)>epsilon);     
svm.a = a(sv_label);
svm.Xsv = X(:,sv_label);
svm.Ysv = Y(sv_label);
svm.svnum = length(sv_label);
%svm.label = sv_label;
end
 
 
 
%---------------�˺���kernel---------------
function K = kernel(X,Y,type)
%X ά��*����
switch type
case 'linear'   %��ʱ�������Ժ�
    K = X'*Y;
case 'rbf'      %��ʱ������˹��
    delta = 0.5;  %�ı��������ͼ���Ĳ�һ����������Խ��֧������Խ�ࡣ����
    delta = delta*delta;
    XX = sum(X'.*X',2);     %2��ʾ�������еİ���Ϊ��λ�������
    YY = sum(Y'.*Y',2);
    XY = X'*Y;
    K = abs(repmat(XX,[1 size(YY,1)]) + repmat(YY',[size(XX,1) 1]) - 2*XY);
    K = exp(-K./delta);
end
end
 
 
 
%---------------���Եĺ���svmTest-------------
function result = svmTest(svm, Xt, Yt, kertype)
temp = (svm.a'.*svm.Ysv)*kernel(svm.Xsv,svm.Xsv,kertype);
%total_b = svm.Ysv-temp;
b = mean(svm.Ysv-temp);  %bȡ��ֵ
w = (svm.a'.*svm.Ysv)*kernel(svm.Xsv,Xt,kertype);
result.score = w + b;
Y = sign(w+b);  %f(x)
result.Y = Y;
result.accuracy = size(find(Y==Yt))/size(Yt);
end
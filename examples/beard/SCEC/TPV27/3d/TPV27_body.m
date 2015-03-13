clear

sim_name = 'TPV27_base_';

names = {...
         [sim_name,'body030st-050dp000'],...
         [sim_name,'body030st-050dp000'],...
         [sim_name,'body-030st-050dp000'],...
         [sim_name,'body030st050dp000'],...
         [sim_name,'body-030st050dp000'],...
         [sim_name,'body030st150dp000'],...
         [sim_name,'body-030st150dp000'],...
 };


for k = 1:length(names)
  pd = process_body_station(names{k},'data');

  if(isempty(pd))
    disp(['NOT FOUND :: ',names{k}])
  else
    disp(['    FOUND :: ',names{k}])
    t  = pd.t;
    u1 = zeros(size(t));
    u2 = zeros(size(t));
    u3 = zeros(size(t));
    v1 = pd.v1;
    v2 = pd.v2;
    v3 = pd.v3;
    write_scec_data(['scec/',names{k},'.scec'],pd.header,...
       't  h-disp  h-vel  v-disp  v-vel  n-disp  n-vel',...
       [t, u1, v1, u2, v2, u3, v3]);
    disp(pd.t(end))
  end
end

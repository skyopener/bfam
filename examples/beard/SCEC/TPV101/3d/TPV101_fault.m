clear

sim_name = 'TPV101_';

names = {[sim_name,'faultst-090dp075'],...
         [sim_name,'faultst-120dp030'],...
         [sim_name,'faultst-120dp120'],...
         [sim_name,'faultst000dp030' ],...
         [sim_name,'faultst000dp075' ],...
         [sim_name,'faultst000dp120' ],...
         [sim_name,'faultst090dp075' ],...
         [sim_name,'faultst120dp030' ],...
         [sim_name,'faultst120dp120' ]};

for k = 1:length(names)
  pd = process_fault_station([0,0,1],names{k},'data');

  if(isempty(pd))
    disp(['NOT FOUND :: ',names{k}])
  else
    disp(['    FOUND :: ',names{k}])
    m = [1; 0; 0];
    l = [0; 1; 0];
    t       = pd.t+(1.39-0.58);
    hslip   = pd.Dp1*m(1)+pd.Dp2*m(2)+pd.Dp3*m(3);
    hrate   = pd.Vp1*m(1)+pd.Vp2*m(2)+pd.Vp3*m(3);
    hshear  = pd.Tp1*m(1)+pd.Tp2*m(2)+pd.Tp3*m(3);
    vslip   = pd.Dp1*l(1)+pd.Dp2*l(2)+pd.Dp3*l(3);
    vrate   = pd.Vp1*l(1)+pd.Vp2*l(2)+pd.Vp3*l(3);
    vshear  = pd.Tp1*l(1)+pd.Tp2*l(2)+pd.Tp3*l(3);
    nstress = pd.Tn;
    write_scec_data(['scec/',names{k},'.scec'],pd.header,...
       't h-slip h-slip-rate h-shear-stress v-slip v-slip-rate v-shear-stress n-stress log-theta ',...
       [t, hslip, hrate, hshear, vslip, vrate, vshear, nstress, zeros(size(nstress))]);

    disp(pd.t(end))
  end
end

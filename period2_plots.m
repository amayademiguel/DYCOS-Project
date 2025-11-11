%% DYCOS period 2: plots and performance metrics

mdlName = 'power_turbine_period2_1110_plots';   % update if changing model name
outDir  = fullfile(pwd,'fig'); if ~exist(outDir,'dir'), mkdir(outDir); end
Tstop   = 150;                                  % simulation time

% colors and fonts
C.blue  = [0.00 0.20 0.55];
C.red   = [0.55 0.00 0.00];
C.green = [0.00 0.45 0.10];
C.gold  = [0.75 0.55 0.00];
fsAxes  = 16; fsTitle = 18; fsLegend = 16;

% graphics settings
set(groot,'defaultFigureColor','w',...
          'defaultAxesColor','w',...
          'defaultAxesXColor','k','defaultAxesYColor','k','defaultAxesZColor','k',...
          'defaultAxesFontName','Times New Roman','defaultAxesFontSize',fsAxes,...
          'defaultTextFontName','Times New Roman','defaultTextFontSize',fsAxes);

figMedium = @() set(gcf,'Units','pixels','Position',[100 100 1300 550]);
savePNG   = @(fn) print(gcf, fullfile(outDir, fn), '-dpng','-r300');

% simulation run
load_system(mdlName);
set_param(mdlName,'StopTime',num2str(Tstop));
simOut = sim(mdlName);             
S      = simOut;                   

% pulling signals out
[tVt,  Vt]   = pull_signal(S,'Vt');      % terminal voltage (pu)
[tDel, del]  = pull_signal(S,'delta');   % rotor angle (deg)
[tWm,  wm]   = pull_signal(S,'wm');      % rotor speed (pu)
[tVr,  Vr]   = pull_signal(S,'Vr');      % regulator output voltage (pu)
[tI,   Iabc] = pull_signal(S,'Iabc');    % 3-phase stator current (pu)
[tVf,  Vf]   = pull_signal(S,'Vf');      % control input u = field voltage (pu)

% build current magnitude from Iabc
Imag = sqrt(mean(Iabc.^2,2));  

% final steady-state value as reference
tail_len = @(y) max(5, round(0.05*numel(y)));
Vt_ref   = mean(Vt( end-tail_len(Vt)+1 : end ));
del_ref  = mean(del(end-tail_len(del)+1:end));
wm_ref   = mean(wm( end-tail_len(wm)+1 : end ));

% deviations from final steady state
devVt  = Vt  - Vt_ref;
devDel = del - del_ref;
devWm  = wm  - wm_ref;

% maximum deviation
[maxDevVt,  idxMaxVt]  = max(abs(devVt));
[maxDevDel, idxMaxDel] = max(abs(devDel));
[maxDevWm,  idxMaxWm]  = max(abs(devWm));

tMaxVt  = tVt(idxMaxVt);   yMaxVt  = Vt(idxMaxVt);
tMaxDel = tDel(idxMaxDel); yMaxDel = del(idxMaxDel);
tMaxWm  = tWm(idxMaxWm);   yMaxWm  = wm(idxMaxWm);

% settling time (2% band around final steady state)
tolRel = 0.02;
[tSetVt,  ~] = settling_time(tVt,  Vt,  Vt_ref,  tolRel);
[tSetDel, ~] = settling_time(tDel, del, del_ref, tolRel);
[tSetWm,  ~] = settling_time(tWm,  wm,  wm_ref,  tolRel);

% RMS voltage deviation over last 10 s
T_RMS   = 10;                     
tEnd    = tVt(end);
t0_rms  = max(tVt(1), tEnd - T_RMS);
idxRMS  = tVt >= t0_rms;
Vt_dev_window = Vt(idxRMS) - Vt_ref;
RMS_Vt  = sqrt(mean(Vt_dev_window.^2));

% control effort: integral of u^2 dt
controlEffort = trapz(tVf, Vf.^2); % (pu^2·s)

% print simulation metrics
fprintf('\n=== Excitation system performance metrics ===\n');
fprintf('Max deviation Vt:    %.4f pu\n', maxDevVt);
fprintf('Max deviation delta:                      %.4f deg\n', maxDevDel);
fprintf('Max deviation wm:                         %.4f pu\n\n', maxDevWm);

fprintf('Settling time Vt:    %.3f s\n', tSetVt);
fprintf('Settling time delta: %.3f s\n', tSetDel);
fprintf('Settling time wm:    %.3f s\n\n', tSetWm);

fprintf('RMS Vt deviation over last %.1f s: %.4f pu\n', T_RMS, RMS_Vt);
fprintf('Control effort ∫u^2 dt: %.4f (pu^2·s)\n\n', controlEffort);

% helpers for axes 
nice_time_axis_full = @(t) ...
    (set(gca,'XLim',[0 t(end)],...
              'XTick',0:10:(10*ceil(t(end)/10))));
nice_time_axis_zoom = @(t,tmax) ...
    (set(gca,'XLim',[0 min(tmax,t(end))],...
              'XTick',0:5:(5*ceil(min(tmax,t(end))/5))));
nice_y_axis = @(y_all) ylim_local(y_all);

%% figure: Vt
figure; figMedium();
plot(tVt, Vt,'LineWidth',1.9,'Color',C.blue,'DisplayName','V_t'); grid on; hold on;

% reference (green dotted)
yline(Vt_ref,':','Color',C.green,'LineWidth',1.8,'DisplayName','V_{t,ref}');

% settling time (gold dotted)
if ~isnan(tSetVt)
    xline(tSetVt,':','Color',C.gold,'LineWidth',1.8,'DisplayName','t_{set}');
end

% max deviation
plot(tMaxVt,yMaxVt,'o','Color',C.blue,'MarkerSize',7,'DisplayName','max dev');

xlabel('Time [s]');
ylabel('V_t [pu]');
title('Scenario: Terminal voltage','FontSize',fsTitle); %change by the name of the scenario simulated
legend('Location','best','FontSize',fsLegend);
nice_time_axis_full(tVt);
nice_y_axis(Vt);
savePNG('Vt_scenario'); %change by the name of the scenario simulated

%% figure: delta
figure; figMedium();
plot(tDel, del,'LineWidth',1.9,'Color',C.red,'DisplayName','\delta'); grid on; hold on;

yline(del_ref,':','Color',C.green,'LineWidth',1.8,'DisplayName','\delta_{ref}');
if ~isnan(tSetDel)
    xline(tSetDel,':','Color',C.gold,'LineWidth',1.8,'DisplayName','t_{set}');
end
plot(tMaxDel,yMaxDel,'o','Color',C.red,'MarkerSize',7,'DisplayName','max dev');

xlabel('Time [s]');
ylabel('\delta [deg]');
title('Scenario: Rotor angle','FontSize',fsTitle); %change by the name of the scenario simulated
legend('Location','best','FontSize',fsLegend);
nice_time_axis_full(tDel);
nice_y_axis(del);
savePNG('delta_scenario'); %change by the name of the scenario simulated

%% figure: omega
figure; figMedium();
plot(tWm, wm,'LineWidth',1.9,'Color',C.blue,'DisplayName','\omega'); grid on; hold on;

yline(wm_ref,':','Color',C.green,'LineWidth',1.8,'DisplayName','\omega_{ref}');
if ~isnan(tSetWm)
    xline(tSetWm,':','Color',C.gold,'LineWidth',1.8,'DisplayName','t_{set}');
end
plot(tMaxWm,yMaxWm,'o','Color',C.blue,'MarkerSize',7,'DisplayName','max dev');

xlabel('Time [s]');
ylabel('\omega [pu]');
title('Scenario: Rotor speed','FontSize',fsTitle); %change by the name of the scenario simulated
legend('Location','best','FontSize',fsLegend);
nice_time_axis_full(tWm);
nice_y_axis(wm);
savePNG('omega_scenario'); %change by the name of the scenario simulated

%% figure: V_R
figure; figMedium();
plot(tVr,Vr,'LineWidth',1.9,'Color',C.red,'DisplayName','V_R'); grid on;
xlabel('Time [s]');
ylabel('V_R [pu]');
title('Scenario: Regulator output','FontSize',fsTitle); %change by the name of the scenario simulated
legend('Location','best','FontSize',fsLegend);
nice_time_axis_zoom(tVr,30);  % change the number in order to have a different zoom
savePNG('Vr_scenario'); %change by the name of the scenario simulated

%% figure: I magnitude
figure; figMedium();
plot(tI,Imag,'LineWidth',1.9,'Color',C.blue,'DisplayName','|I|'); grid on;
xlabel('Time [s]');
ylabel('I [pu]');
title('Scenario: Stator current magnitude','FontSize',fsTitle); %change by the name of the scenario simulated
legend('Location','best','FontSize',fsLegend);
nice_time_axis_full(tI);
nice_y_axis(Imag);
savePNG('current_scenario'); %change by the name of the scenario simulated

%% figure: control input u
figure; figMedium();
plot(tVf,Vf,'LineWidth',1.9,'Color',C.red,'DisplayName','u = V_f'); grid on;
xlabel('Time [s]');
ylabel('u [pu]');
title('Scenario: Control input u = V_f','FontSize',fsTitle);
legend('Location','best','FontSize',fsLegend);
nice_time_axis_zoom(tVf,30); % change the number in order to have a different zoom
nice_y_axis(Vf);
savePNG('u_scenario'); %change by the name of the scenario simulated

% helper functions
function [t,y] = pull_signal(S, name)
    if ~isprop(S,name)
        error('Signal "%s" not found in SimulationOutput.', name);
    end
    sig = S.(name);
    [t,y] = get_tv(sig);
end

function [t,y] = get_tv(sig)
    if isstruct(sig)
        t = sig.time(:);
        y = sig.signals.values;
        return;
    end
    if isa(sig,'Simulink.SimulationData.Signal')
        ts = sig.Values;
        t  = ts.Time(:);
        y  = ts.Data;
        return;
    end
    if isa(sig,'timeseries')
        t = sig.Time(:);
        y = sig.Data;
        return;
    end
    error('Unsupported signal type: %s', class(sig));
end

function [t_set, idx_set] = settling_time(t,y,yref,tolRel)
    err = abs(y - yref);
    tol = tolRel*max(abs(yref),1e-6);
    idx_out = find(err > tol);

    if isempty(idx_out)
        idx_set = 1;
        t_set   = t(1);
    else
        last_out = idx_out(end);
        if last_out == numel(t)

            idx_set = NaN;
            t_set   = NaN;
        else
            idx_set = last_out + 1;
            t_set   = t(idx_set);
        end
    end
end

function ylim_local(y_all)
    y_all = y_all(:);
    yMin = min(y_all);
    yMax = max(y_all);
    if yMax == yMin
        margin = max(0.01,0.05*abs(yMax));
        ylim([yMin-margin yMax+margin]);
    else
        margin = 0.05*(yMax - yMin);
        ylim([yMin-margin yMax+margin]);
    end
end

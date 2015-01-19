Te = 1E6;
t = 0:8/Te:8-1/Te;
preambule = [ones(1,Te/16), zeros(1,Te/16), ones(1,Te/16), zeros(1,Te/4), ones(1,Te/16), zeros(1,Te/16), ones(1,Te/16), zeros(1,3*Te/8)];
plot(t, preambule)
xlim([-0.05 8.05])
ylim([-0.05 1.05])
xlabel('Temps en µs')
ylabel('Amplitude de s_p(t) (sans unité)')
grid on
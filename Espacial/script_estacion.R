source("Espacial/Preliminar.R")

Estaciones <- readxl::read_excel("Datos/Estaciones.xlsx")

Estaciones <- as.matrix(Estaciones)

est = 1
S_1 = na.exclude(Estaciones[,est])

n = length(S_1) 
chains = 4
iter = 100

## Construccion del DLM 
dlm_temp = dlm::dlm(GG = I, FF = t(Kij[1,]), V = 1, W = I, m0 = rep(0,18), 
                    C0 = 100*I)

## Aplicacion de FFBS
ft = matrix(0,nrow = chains*iter, ncol = n+1)

for(i in 1:(chains*iter)){
  Mu = dlm::dlmBSample(dlm::dlmFilter(y = S_1,mod = dlm_temp))
  ft[i,] = Mu %*% Kij[est,]
}

# Media a posterior del DLM 
ft_mean = apply(ft,2,mean)

ft = ft[,1:n]
colnames(ft) = paste0("mu",1:n)

# Estimacion de los parametros del GEV
z = S_1 - ft_mean[-1]
post2 = sampling(y = z, scale = diag(2),thin = 1, refresh = 0, iter = iter, 
                 h = 0.01, positive = 1)

# Revisamos las posterior
colnames(post2) = c(".chain","acceptance_rate","sigma","k")
post1_df = as_draws_df(post2)
summarise_draws(post1_df)

mcmc_combo(post1_df,pars = c("sigma","k"))

#Agregamos las cadenas del FFBS al Metropolis
post2 = cbind(post2,ft)

# Posterior predictive checks
y_rep = apply(post2,1,FUN = function(x){
  x = as.numeric(x)
  SpatialExtremes::rgev(908,loc = 0,scale = x[3],shape = x[4]) + x[1:n + 4]
})

#s = sample(1:iter,size = 500)
#y_rep_try = t(y_rep)[s,]

#color_scheme_set("viridisD")
#g1 = ppc_dens_overlay(y = as.numeric(S_1),yrep = y_rep_try,trim = FALSE)
#g2 = ppc_ribbon(y = as.numeric(S_1),yrep = t(y_rep))
# graficos de los ppc
#cowplot::plot_grid(g1,g2,ncol = 1)

# Grafico del Ajuste del modelo a la estacion 
g2 = ppc_ribbon(y = as.numeric(S_1),yrep = t(y_rep)) + 
  labs(title = "Revisión de la predictiva",subtitle = paste("Estación",est),
       x = "tiempo",y = "Precipitaciones")

g2

#  Guardar la posterior
write.csv(post2,file = paste0("Datos/Post_est",est,".csv"))

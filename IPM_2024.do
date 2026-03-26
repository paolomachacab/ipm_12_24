****************************************************************************
***** SDSN 2025 *****
****************************************************************************

* Organización:	SDSN
* Objetivo:	Generar el indicador de IPM a partir del censo 2024
* Fecha: Octubre, 2025
* Revisado por:	Paolo Machacay Fabiana Argandoña
* Elaborado por: Bruna Torrico
* Comentarios a: brunatorriale@gmail.com
****************************************************************************
****************************************************************************
clear all 
set more off
version 17.0
******************************************************************************

if ("`c(username)'" == "BRUNA") { // Bruna Torrico (laptop)
	global path	"C:\Bruna\sdsn"
	global in 	"$path/_in"
	global out  "$path/_out"
	global code "$path/_code"
	global tbl	"$path/_tbl"
	global graph  "$path/_graph"
}
******************************************************************************
* Realizar el merge entre base personas y base vivienda
use "$out/personas_vivienda_censo_2024", replace*

* Creación devariable que distingue a las viviendas particulares
cap drop particular		
gen particular=.
replace particular =1 if inlist(v01_tipoviv,1,2,3,4,5,6)   
replace particular =0 if inlist(v01_tipoviv,7,8,9,10,11,12,13,14,15,16)	

keep if particular==1

****************************************************************************
* Creación de 9 indicadores 
****************************************************************************

****************************************************************************
* Dimensión: Poder y voz
****************************************************************************
*---------------------------------------------------------------------------
* 1. Analfabetismo
*----------------------------------------------------------------------------
/*	*P40_LEE  40.   Sabe leer y escribir
	1	Sí
    2	No */

* 1) Variable individual: 1 si persona tiene 15+ años y no sabe leer
cap drop analfabetismo_ind
gen analfabetismo_ind = .
replace analfabetismo_ind = 1 if p26_edad >= 15 & p40_lee == 2
replace analfabetismo_ind = 0 if p26_edad >= 15 & p40_lee == 1

replace analfabetismo_ind = 0 if p26_edad <15 

	
* 2) Variable a nivel hogar: 1 si al menos una persona del hogar tiene analfabetismo_ind==1
cap drop analfabetismo_hogar
bysort i00: egen analfabetismo_hogar = max(analfabetismo_ind)

	
* Crear labels
label var analfabetismo_hogar "Privación por analfabetismo (1=privado)"
label define priv_label 0 "No privación" 1 "Privación"
label values analfabetismo_hogar priv_label

* Revisar la tabulación
tab analfabetismo_hogar,m 

*---------------------------------------------------------------------------
* 2. Documento de identidad
*---------------------------------------------------------------------------
/*P29_CI  29.   Tiene o tuvo cédula de identidad boliviana
	1	Sí
	2	No
	3	Cédula Boliviana de extranjero
	9	Sin especificar */

* 1) Variable individual: 1 si persona tiene 6+ años y no tiene carnet de identidad
cap drop sin_carnet_ind
gen sin_carnet_ind = .
replace sin_carnet_ind =1 if p26_edad >= 6 & p29_ci == 2
replace sin_carnet_ind =0 if p26_edad >= 6 & inlist(p29_ci,1,3) 
replace sin_carnet_ind =0 if p26_edad < 6
	
* 2) Variable a nivel hogar: 1 si al menos una persona del hogar tiene analfabetismo_ind==1
cap drop sin_carnet_hogar
bysort i00: egen sin_carnet_hogar = max(sin_carnet_ind)

* Crear labels
label var sin_carnet_hogar "Privación en documento de identidad (1=privado)"
label define carnet_label 0 "No privación" 1 "Privación"
label values sin_carnet_hogar carnet_label

* Revisar la tabulación
tab sin_carnet_hogar,m 

*---------------------------------------------------------------------------
* 3. Comunicación 
*---------------------------------------------------------------------------
*sección de vivienda
/*  *V19D_CELULAR   19.4. Su hogar tiene: Teléfono celular
	*V19H_TELFIJO 19.8. Su hogar tiene: Servicio de telefonía fija
1	Sí
2	No
9	Sin especificar */

cap drop priv_comunicacion
gen priv_comunicacion = .
replace priv_comunicacion = 1 if (v19d_celular == 2 | v19h_telfijo==2) 
replace priv_comunicacion = 0 if v19d_celular == 1 | v19h_telfijo == 1

* Crear labels
label var priv_comunicacion "Privación por analfabetismo (1=privado)"
label define priv_comunicacion_label 0 "No privación" 1 "Privación"
label values priv_comunicacion priv_comunicacion_label

* Revisar la tabulación
tab priv_comunicacion,m 

	
****************************************************************************
* Dimensión: Oportunidades y elección
****************************************************************************
*--------------------------------------------------------------------------
* 4. Salud (parto no atendido en un centro de salud)
*---------------------------------------------------------------------------    

*--------------------------------------------------------*
* Variable que identifica los últimos 5 años 
replace p57b_uhnacan = . if p57b_uhnacan == 9999

cap drop ult_año
gen ult_año=2024

cap drop ult5años
gen ult5años = ult_año-p57b_uhnacan<5 if !missing(p57b_uhnacan)
tabstat p57b_uhnacan if ult5años==1, stats(max min mean)
*--------------------------------------------------------*

* 1) Variable que identifica los partos atendidos por personal calificado
cap drop priv_parto
gen priv_parto = .
replace priv_parto = 0 if ult5años==1 & (p26_edad >=15 & p26_edad <=59)  & p25_sexo==1 & inlist(p59_atparto,1,2,3) 
		
* Privadas las mujeres que no fueron atendidas por personal calificado y su parto fue en los últimos 5 años	
replace priv_parto = 1 if ult5años==1 & (p26_edad >=15 & p26_edad <=59)  & p25_sexo==1 & inlist(p59_atparto,4,5,6,7,8) 

* No privadas las mujeres que no fueron atendidas por personal calificado y su parto no fue en los últimos 5 años 	
replace priv_parto = 0 if ult5años==0 & inlist(p59_atparto,4,5,6,7,8) & p25_sexo==1

* No privadas las mujeres que fueron atendidas por personal calificado y su parto no fue en los últimos 5 años 	
replace priv_parto = 0 if ult5años==0 & inlist(p59_atparto,1,2,3) & p25_sexo==1

* No privadas las mujeres menores a 15 y mayores a 59 años de edad 
replace priv_parto = 0 if p25_sexo==1 & (p26_edad < 15 | p26_edad > 59) 

replace priv_parto = 0 if p25_sexo==2

replace priv_parto = 0 if p25_sexo==1 & p54_hvtot==0

* 2) Variable a nivel hogar: 1 si al menos una persona del hogar en edad fértil que no fue atendida por personal de salus calificado

cap drop priv_parto_hogar
bysort i00: egen priv_parto_hogar = max(priv_parto)
	
* Crear labels
label var priv_parto_hogar "Privación en atención en el parto (1=privado)"
label define priv_parto_hogar_label 0 "No privación" 1 "Privación"
label values priv_parto_hogar priv_parto_hogar_label

* Revisar la tabulación
tab priv_parto_hogar,m 
           	 
*--------------------------------------------------------------------------
* 5. Embarazo adolescente  
*--------------------------------------------------------------------------
/*Desde 10 a 24 años
Se utiliza el número de hijos nacidos vivos o muertos 
Se utiliza los últimos 5 años
*/

* 1. Crear variable individual de embarazo adolescente reciente
cap drop embarazo_ado_reciente
gen embarazo_ado_reciente = .
	
* Privación si tuvo su primer hijo hasta los 19 años (embarazo adolescente) y fue en los últimos 5 años
replace embarazo_ado_reciente = 1 if inrange(p26_edad, 12, 19) & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1

replace embarazo_ado_reciente = 1 if inrange(p26_edad, 12, 19) & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1

* No privación si tuvo su primer hijo antes de los 19 años (embarazo adolescente) pero. fue hace más de 5 años
replace embarazo_ado_reciente = 0 if inrange(p26_edad, 12, 19) & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 0

replace embarazo_ado_reciente = 0 if inrange(p26_edad, 12, 19) & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 0

*&
* Privación si tuvo su primer hijo hasta los 24 años que era adolescente al momento de su embarazo y fue en los últimos 5 años
***Privación si tiene 24 al momento del Censo pero era adolescente al momento de su último parto: 

replace embarazo_ado_reciente = 1 if p26_edad == 24 & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1 & p57b_uhnacan<=2019

replace embarazo_ado_reciente = 1 if p26_edad == 24 & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1 & p57b_uhnacan<=2019

replace embarazo_ado_reciente = 0 if p26_edad == 24 & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1 & p57b_uhnacan>2019

replace embarazo_ado_reciente = 0 if p26_edad == 24 & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1 & p57b_uhnacan>2019

*&
***Privación si tiene 23 al momento del Censo pero era adolescente al momento de su último parto: 

replace embarazo_ado_reciente = 1 if p26_edad == 23 & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1 & p57b_uhnacan<=2020

replace embarazo_ado_reciente = 1 if p26_edad == 23 & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1 & p57b_uhnacan<=2020

replace embarazo_ado_reciente = 0 if p26_edad == 23 & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1 & p57b_uhnacan>2020

replace embarazo_ado_reciente = 0 if p26_edad == 23 & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1 & p57b_uhnacan>2020

***Privación si tiene 22 al momento del Censo pero era adolescente al momento de su último parto: 

replace embarazo_ado_reciente = 1 if p26_edad == 22 & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1 & p57b_uhnacan<=2021

replace embarazo_ado_reciente = 1 if p26_edad == 22 & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1 & p57b_uhnacan<=2021

replace embarazo_ado_reciente = 0 if p26_edad == 22 & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1 & p57b_uhnacan>2021

replace embarazo_ado_reciente = 0 if p26_edad == 22 & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1 & p57b_uhnacan>2021

***Privación si tiene 21 al momento del Censo pero era adolescente al momento de su último parto (no privacion si no era adolescente al momento del parto) 

replace embarazo_ado_reciente = 1 if p26_edad == 21 & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1 & p57b_uhnacan<=2022

replace embarazo_ado_reciente = 1 if p26_edad == 21 & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1 & p57b_uhnacan<=2022

replace embarazo_ado_reciente = 0 if p26_edad == 21 & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1 & p57b_uhnacan>2022

replace embarazo_ado_reciente = 0 if p26_edad == 21 & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1 & p57b_uhnacan>2022

***Privación si tiene 20 al momento del Censo pero era adolescente al momento de su último parto (no privacion si no era adolescente al momento del parto) 

replace embarazo_ado_reciente = 1 if p26_edad == 20 & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1 & p57b_uhnacan<=2023

replace embarazo_ado_reciente = 1 if p26_edad == 20 & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1 & p57b_uhnacan<=2023

replace embarazo_ado_reciente = 0 if p26_edad == 20 & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 1 & p57b_uhnacan>2023

replace embarazo_ado_reciente = 0 if p26_edad == 20 & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 1 & p57b_uhnacan>2023

* No privación si tuvo su primer hijo entre los 12 a 24 años (embarazo adolescente, ya que si tiene 24 hace 5 años tenia 19); sin embargo, fue hace más de 5 años
replace embarazo_ado_reciente = 0 if inrange(p26_edad, 12, 24) & (p54_hvtot>0 & p54_hvtot<=98) & ult5años == 0

replace embarazo_ado_reciente = 0 if inrange(p26_edad, 12, 24) & (p54_hvtot==99 & p59_atparto!=9) & ult5años == 0


* No privación si la mujer no tuvo hijos y si está fuera del rango de edad analizado 
replace embarazo_ado_reciente = 0 if p25_sexo == 1 & p54_hvtot == 0 
replace embarazo_ado_reciente = 0 if p25_sexo == 1 & p26_edad<12
replace embarazo_ado_reciente = 0 if p25_sexo == 1 & p26_edad>24
replace embarazo_ado_reciente = . if p25_sexo == 1 & p54_hvtot == 9 & p59_atparto == 99

* No privación si es hombre
replace embarazo_ado_reciente = 0 if p25_sexo == 2	
	  
* 2. Colapsar a nivel hogar: al menos un caso en el hogar
cap drop embarazo_adolescente_2024
bysort i00: egen embarazo_adolescente_2024 = max(embarazo_ado_reciente)

* Crear labels
label var embarazo_adolescente_2024 "Privación por embarazo adolescente (1=privado)"
label define embarazo_adolescente_2024_label 0 "No privación" 1 "Privación"
label values embarazo_adolescente_2024 embarazo_adolescente_2024_label

* Revisar la tabulación
tab embarazo_adolescente_2024,m // 

*--------------------------------------------------------------------------
* 6. Educación
*--------------------------------------------------------------------------
*P38_ASISTE  38. Actualmente, asiste como estudiante a:
*ASISTE      Asistencia educativa (residentes en el país y que respondieron a la pregunta)
	
* variable incluyendo residentes y no residentes
*-----------------------------------------------*
cap drop sin_asistencia
gen sin_asistencia = .
replace sin_asistencia = 1 if inrange(p26_edad, 6, 19) & p38_asiste == 8
replace sin_asistencia = 0 if inrange(p26_edad, 6, 19) & inlist(p38_asiste,1,2,3,4,5,6,7)

replace sin_asistencia = 0 if (p26_edad < 6 | p26_edad > 19) 

cap drop asistencia_hogar
bysort i00: egen asistencia_hogar = max(sin_asistencia)

* Crear labels
label var asistencia_hogar "Privación por analfabetismo (1=privado)"
label define asistencia_hogar_label 0 "No privación" 1 "Privación"
label values asistencia_hogar asistencia_hogar_label

* Revisar la tabulación
tab asistencia_hogar,m 

*****************************************************************************
* Dimensión: Recursos
*****************************************************************************
*--------------------------------------------------------------------------
* 7. Agua potable
*--------------------------------------------------------------------------
*V07_AGUAPRO  7. Principalmente, el agua que usan en la vivienda proviene de:
/*
1 Cañería de red							No privado
2 Pileta pública							No privado
3 Cosecha de agua de lluvia					No privado 
4 Pozo excavado o perforado con bomba		No privado	
5 Pozo no protegido o sin bomba				Privado
6 Manantial o vertiente protegida			No privado
7 Rio, acequia o vertiente no protegida		Privado
8 Carro repartidor (aguatero)				Privado *
9 Otro"										Privado
*/	

*V08_AGUADIST 8. El agua que usan en la vivienda se distribuye:
/*
1	Por cañería dentro de la vivienda		No privado
2	Por cañería fuera de la vivienda, 
	pero dentro del lote o terreno			No privado
3	No se distribuye por cañería			Privado
*/

/* Definición del INE: en área urbana, se considera a la población que tiene acceso a agua por: Cañería de red dentro de la vivienda. Cañería de red fuera de la vivienda, pero dentro del lote o terreno. Pileta pública y cosecha de agua de lluvia*/

cap drop agua_potable
gen agua_potable=.
replace agua_potable=0 if v07_aguapro==1 & inlist(v08_aguadist,1,2) & urbrur==1
replace agua_potable=0 if v07_aguapro==2 & urbrur==1
replace agua_potable=0 if v07_aguapro==3 & urbrur==1

/* Definición del INE: en área rural el acceso a agua por cañería de red dentro de la vivienda, cañería de red fuera de la vivienda pero dentro del lote o terreno, pileta pública, Pozo excavado o perforado con bomba, cosecha de agua de lluvia y vertiente protegida */

replace agua_potable=0 if v07_aguapro==1 & inlist(v08_aguadist,1,2) & urbrur==2
replace agua_potable=0 if v07_aguapro==2 & urbrur==2
replace agua_potable=0 if v07_aguapro==3 & urbrur==2
replace agua_potable=0 if v07_aguapro==4 & urbrur==2
replace agua_potable=0 if v07_aguapro==6 & urbrur==2

/* Usando una pregunta, el resultado es el mismo
cap drop agua_potable
gen agua_potable=.
replace agua_potable=0 if inlist(v07_aguapro,1,2,3) & urbrur==1
replace agua_potable=0 if inlist(v07_aguapro,1,2,3,4,6) & urbrur==2
*/

replace agua_potable=1 if agua_potable==.

* Crear labels
label var agua_potable "Privación en agua mejorada (1=privado)"
label define agua_potable_label 1 "Privado" 0 "No privado"
label values agua_potable agua_potable_label

* Revisar la tabulación
tab agua_potable,m 

*--------------------------------------------------------------------------
* 8. Electricidad
*--------------------------------------------------------------------------
*V09_ENERGIA   9. De donde proviene la energía eléctrica que usan en la vivienda

cap drop priv_electricidad  
gen priv_electricidad = .
replace priv_electricidad = 1 if inlist(v09_energia,5)
replace priv_electricidad = 0 if inlist(v09_energia,1,2,3,4)
	
* Crear labels
label var priv_electricidad "Privación en electricidad (1=privado)"
label define priv_electricidad_label 0 "No privación" 1 "Privación"
label values priv_electricidad priv_electricidad_label

* Revisar la tabulación
tab priv_electricidad, m 
	
*--------------------------------------------------------------------------
* 9. Saneamiento básico
*--------------------------------------------------------------------------
*V15_SERVSAN   15. Tienen, baño o letrina
*V16_DESAGUE   16. El baño o letrina tiene desagüe:

/*
1	Sí, usado solo por su hogar					No privada
2	Sí, compartido con otros hogares			No privada
3	No tiene									Privada
*/

/* v16_desague:
1	A la red de alcantarillado					No privado
2	A una cámara séptica						No privado
3	A un pozo ciego								No privado
4	A un pozo de absorción						No privado
5	A la superficie (calle, quebrada o río)		Privado
6	Es baño ecológico							No privado
*/

cap drop saneamiento
gen saneamiento = .

/* Definición del INE: en área urbana se considera a la población que tiene acceso a servicio de alcantarillado y baño ecológico (baño de compostaje) */ 

replace saneamiento = 0 if inlist(v16_desague,1,6) & urbrur==1

/* Definición del INE: en área rural el acceso a servicio de alcantarillado, cámara séptica, pozo de absorción, pozo ciego. y baño ecológico (baño de compostaje)*/

replace saneamiento = 0 if inlist(v16_desague,1,2,3,4,6) & urbrur==2

replace saneamiento=1 if saneamiento==.

* Crear labels
label var saneamiento "Privación de saneamiento mejorado (1=privado)"
label define saneamiento_label 0 "No privación" 1 "Privación"
label values saneamiento saneamiento_label

* Revisar la tabulación
tab saneamiento,m 

*****************************************************************************
* Unifizar nombre de las variables
*****************************************************************************

rename analfabetismo_hogar conanalfabeto2024
rename sin_carnet_hogar sincarnet2024
rename priv_comunicacion sintelefono2024
rename priv_parto_hogar sinaccesoasalud2024
rename embarazo_adolescente_2024 conembarazoadolescente2024
rename asistencia_hogar conjovenquenoestudia2024
rename agua_potable sinaguapotable2024
rename priv_electricidad sinelectricidad2024
rename saneamiento sinsaneamientobasico2024

*****************************************************************************
* Crear variables en base a la vivienda
*****************************************************************************

*Guardar copia de respaldo
save "$out/base_individual_original", replace

use "$out/base_individual_original", clear 

* Crear una observación a nivel de vivienda
collapse (max) conanalfabeto2024 sincarnet2024 sintelefono2024 sinaccesoasalud2024 conembarazoadolescente2024 conjovenquenoestudia2024 sinaguapotable2024 sinelectricidad2024 sinsaneamientobasico2024 mun_res_cod urbrur dep_res_cod codm, by(i00)

save "$out/base_vivienda_collapse", replace

use "$out/base_vivienda_collapse", clear 

* Guardar en CSV (compatible con Excel)
export delimited using "$out/base_vivienda_collapse.csv", replace

 
*****************************************************************************
* Definir los pesos de los indicadores
*****************************************************************************
global indicadores "conanalfabeto2024 sincarnet2024 sintelefono2024 sinaccesoasalud2024 conembarazoadolescente2024 conjovenquenoestudia2024 sinaguapotable2024 sinelectricidad2024 sinsaneamientobasico2024"

foreach var of global indicadores{
capture drop w_`var'
	gen	w_`var' = 1/9
	lab var w_`var' "Peso `var'"
}

*****************************************************************************
* Matriz de privaciones 
*****************************************************************************
  
foreach var in conanalfabeto2024 sincarnet2024 sintelefono2024 sinaccesoasalud2024 conembarazoadolescente2024 conjovenquenoestudia2024 sinaguapotable2024 sinelectricidad2024 sinsaneamientobasico2024{	
	cap drop g0_w_`var'
	gen	g0_w_`var' = `var' * w_`var'
	lab var g0_w_`var' "Privación ponderada de `var'"
	}
	
*****************************************************************************  Definir vector de conteo (ci)
*****************************************************************************
egen c_vector = rowtotal(g0_w_*)
lab var c_vector "Vector de conteo"
tab	c_vector , m

****************************************************************************
* Cantidad de Pobres Multidimensionales: MANUAL con k = 0.33 (3 dimensiones)
****************************************************************************

*  Identificar los hogares pobres multidimensionales
gen _mpi_h = 1		if c_vector >= 0.33 & c_vector != . /* Punto de corte */
gen _mpi_e = 1      if c_vector >= 0.44 & c_vector != . /* Punto de corte IPM_extremo*/

replace _mpi_h = 0	if c_vector < 0.33
count if _mpi_h==1

* Calcular privaciones ponderadas
gen _mpi_m0 = c_vector 	
replace _mpi_m0 = 0 if _mpi_h == 0

gen _mpi_a = c_vector if _mpi_h == 1

* Calcular la incidencia (H) // 				corte >=0.33
count if _mpi_h == 1
local q = r(N)
count if c_vector != .
local n = r(N)
local H = (`q' / `n') * 100

* Calcular la incidencia extrema (H) // 		corte >=0.44
count if _mpi_e == 1
local qe = r(N)
count if c_vector != .
local n = r(N)
local He = (`qe' / `n') * 100

* Calcular la intensidad (A)
summarize _mpi_a
local A = r(mean) * 100

* Calcular el índice de pobreza multidimensional (MPI)
local MPI = (`H' * `A') / 100

* Mostrar resultados
display "--------------------------------------------"
display "Índice de Pobreza Multidimensional (nivel nacional)"
display "--------------------------------------------"
display "Incidencia (H): " %6.2f `H' " %"		//
display "Incidencia (He): " %6.2f `He' " %"     // 
display "Intensidad (A): " %6.2f `A' " %"		// 
display "MPI (H × A / 100): " %6.3f `MPI'		// 
display "--------------------------------------------"


****************************************************************************
* Generación de Tablas: MEDIDAS H, A, M0, V, S (por municipios)
****************************************************************************

***************************************************************
* Calcular MPI por municipio con k = 0.33
***************************************************************

preserve

gen uno = 1

collapse ///
    (mean) H =_mpi_h ///
	(mean) A=_mpi_a ///
    (count) hogares = uno ///
    , by(codm)

gen MPI = H * A

label var H   "Incidencia multidimensional (H)"
label var A   "Intensidad (A)"
label var MPI "Índice de Pobreza Multidimensional (MPI)"
label var hogares "Número de hogares"

sort codm 

save "$out/ipm_municipal_2024.dta", replace
export delimited using "$out/mpi_municipal_2024.csv", replace
export excel using "$out/mpi_municipal_2024.xlsx", replace firstrow(variables)

restore

****************************************************************************
* Porcentaje de privaciones por indicador (por municipios)
****************************************************************************

foreach var of global indicadores {
    bys codm: egen total_`var' = total(`var')
    bys codm: egen total_hogares = total(!missing(`var'))
	gen can_`var' = total_`var'
    gen prop_`var' = (total_`var'/total_hogares)*100
    label var prop_`var' "Proporción de hogares con `var' (%)"
    drop total_`var' total_hogares
}

preserve
collapse (mean) prop_*, by(codm)
foreach var of varlist prop_* {
    replace `var' = round(`var',0.01)
}
sort codm

restore

* Guardar en CSV (compatible con Excel)
export delimited using "$out/prop_municipal_2024.csv", replace
* Exporta el CSV indicando que use punto decimal sin separadores de miles
export delimited using "$out/prop_municipal_2024.csv", replace nolabel
restore


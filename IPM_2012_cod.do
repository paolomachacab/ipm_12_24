********************************************************************************
***** SDSN 2025 - CENSO 2012 (IPM Municipal)
********************************************************************************

********************************************************************************
* CONFIGURACIÓN DE RUTAS
**************************************************************************
clear all 
set more off
version 17.0
**************************************************************************

if ("`c(username)'" == "Paolo") { // Paolo Machaca (laptop)
	global path	"C:\Paolo\ipm_2012_sdsn"
	global in 	"$path/_in"
	global out  "$path/_out"
	global code "$path/_code"
	global tbl	"$path/_tbl"
	global graph  "$path/_graph"
}
use "$out/persona_vivienda_censo_2012", clear
 
********************************************************************************
* FILTRAR VIVIENDAS PARTICULARES
********************************************************************************
keep if inrange(P01_TIPOVIV,1,5) 

********************************************************************************
* DIMENSIÓN: PODER Y VOZ
********************************************************************************
*---------------------------------------------------------------------------
* 1. ANALFABETISMO (P35_LEER + edad)
*---------------------------------------------------------------------------
/*
P35_LEER – 35. ¿Sabe leer y escribir?
    1 Sabe leer y escribir (No privado)
    2 No sabe leer (Privado si edad ≥ 15)
    9 Sin especificar 
P25_EDAD – 25. Edad
    (La privación solo se evalúa en población de 15 años o más)
*/

* Criterio:
*   PRIVADO si:
*       - P25_EDAD ≥ 15 y P35_LEER {2}
*   NO PRIVADO si:
*       - P25_EDAD ≥ 15 y P35_LEER == 1
*       - P25_EDAD < 15  
*--------------------------------------------------------------------------
cap drop analfabetismo_ind
gen analfabetismo_ind = .
replace analfabetismo_ind = 1 if P25_EDAD>=15 & inlist(P35_LEER,2)
replace analfabetismo_ind = 0 if P25_EDAD>=15 & P35_LEER==1
replace analfabetismo_ind = 0 if P25_EDAD <15


cap drop analfabetismo_hogar
bys I_BC_VIV: egen analfabetismo_hogar = max(analfabetismo_ind)
label var analfabetismo_hogar "Privación por analfabetismo (1=privado)"

*---------------------------------------------------------------------------
* 2. DOCUMENTO DE IDENTIDAD (P27_CARNET + edad)
*---------------------------------------------------------------------------

/*
P27_CARNET – 27. ¿Tiene carnet/cédula de identidad?
    1 Sí (No privado)
    2 No (Privado si edad ≥ 6)

P25_EDAD – Edad
    (Privación solo se evalúa en 6 años o más)
*/

* Criterio:
*   PRIVADO si:
*       - P25_EDAD ≥ 6 y P27_CARNET == 2
*   NO PRIVADO si:
*       - P25_EDAD ≥ 6 y P27_CARNET == 1
*       - P25_EDAD < 6
*--------------------------------------------------------------------------
cap drop sin_carnet_ind
gen sin_carnet_ind = .
replace sin_carnet_ind = 1 if P25_EDAD>=6 & P27_CARNET==2
replace sin_carnet_ind = 0 if P25_EDAD>=6 & P27_CARNET==1
replace sin_carnet_ind = 0 if P25_EDAD<6
cap drop sin_asistencia_hogar
bys I_BC_VIV: egen sin_carnet_hogar = max(sin_carnet_ind)
label var sin_carnet_hogar "Privación en documento de identidad (1=privado)"


*---------------------------------------------------------------------------
* 3. COMUNICACIÓN (P17E_TELEF)
*---------------------------------------------------------------------------

/*
P17E_TELEF – ¿El hogar tiene telefonía fija o celular?
    1 Sí (No privado)
    2 No (Privado)
*/

* Criterio:
*   PRIVADO si P17E_TELEF == 2
*   NO PRIVADO si P17E_TELEF == 1
*--------------------------------------------------------------------------
cap drop priv_comunicacion
gen priv_comunicacion = .
replace priv_comunicacion = 1 if P17E_TELEF==2
replace priv_comunicacion = 0 if P17E_TELEF==1
label var priv_comunicacion "Privación en comunicación (1=privado)"


********************************************************************************
* DIMENSIÓN: OPORTUNIDADES Y ELECCIÓN
********************************************************************************
*---------------------------------------------------------------------------
* 4. SALUD: PARTO NO ATENDIDO EN CENTRO DE SALUD
*    (P49B_LUGARPARTO + P48B_ANO + P24_SEXO + P25_EDAD)
*---------------------------------------------------------------------------

/*
P24_SEXO – Sexo de la persona
    1 Mujer
    2 Hombre  (No privado en este indicador)

P48B_ANO – Año del último nacimiento
    Solo se consideran partos en los últimos 5 años: 2008–2012

P49B_LUGARPARTO – ¿Dónde tuvo lugar su último parto?
    1 En establecimiento de salud (No privado)
    2 En domicilio (Privado)
    3 En otro lugar (Privado)

Condición adicional basada en evidencia empírica:
    Rango real de edad de mujeres con partos observados en los últimos 5 años = 15–58 años
    → Se excluye mujeres <15 y >58 para evitar incluir partos muy antiguos.

Combinaciones válidas:
    Mujer (P24_SEXO==1) con parto en los últimos 5 años:
        - Lugar 1 → No privado
        - Lugar ∈ {2,3} → Privado

    Mujer sin partos → No privado
    Mujer <15 o >58 años (en los últimos 5 años) → No privado
    Hombre (P24_SEXO==2) → No privado
*/

* Criterio final (nivel individuo):
*   PRIVADO si:
*       - Mujer (P24_SEXO==1)
*       - Edad 15–58 años
*       - Parto en los últimos 5 años (P48B_ANO ∈ 2008–2012)
*       - Lugar ∈ {2,3}
*
*   NO PRIVADO si:
*       - Mujer con parto en los últimos 5 años y lugar == 1
*       - Mujer sin partos
*       - Mujer <15 o >58 años (en los últimos 5 años)
*       - Hombre
*-------------------------------------------------------------------------
* Variable que identifica los últimos 5 años 
cap drop ult5años
gen ult5años = 0
replace ult5años = 1 if P48B_ANO==2007 & inrange(P48A_MES,11,12) 
replace ult5años = 1 if P48B_ANO==2008 
replace ult5años = 1 if P48B_ANO==2009 
replace ult5años = 1 if P48B_ANO==2010 
replace ult5años = 1 if P48B_ANO==2011 
replace ult5años = 1 if P48B_ANO==2012 & inrange(P48A_MES,1,10) 
*-------------------------

cap drop parto_no_salud_ind
gen parto_no_salud_ind = .   

replace parto_no_salud_ind = 1 if P24_SEXO==1 ///
    & inrange(P25_EDAD,15,59) ///
    & ult5años == 1 ///
    & inlist(P49B_LUGARPARTO,2,3)
	
replace parto_no_salud_ind = 0 if P24_SEXO==1 ///
    & inrange(P25_EDAD,15,59) ///
    & ult5años == 1 /// 
    & inlist(P49B_LUGARPARTO,1)

replace parto_no_salud_ind = 0 if P24_SEXO==1 ///
    & P46_NACIDOSVIV==0

replace parto_no_salud_ind = 0 if P24_SEXO==1 ///
    & (P25_EDAD < 15 | P25_EDAD > 59)

replace parto_no_salud_ind = 0 if P24_SEXO==2

tab parto_no_salud_ind, m

cap drop parto_no_salud_hogar
bys I_BC_VIV: egen parto_no_salud_hogar = max(parto_no_salud_ind)

cap label define priv_label 0 "No privación" 1 "Privación"
label var parto_no_salud_hogar "Privación: parto fuera de centro de salud (1 = privado)"
label values parto_no_salud_hogar priv_label

tab parto_no_salud_hogar, m

*---------------------------------------------------------------------------
* 5. EMBARAZO ADOLESCENTE
*---------------------------------------------------------------------------
/*
P24_SEXO – Sexo
    1 Mujer (se evalúa privación)
    2 Hombre (No privado en este indicador)

P25_EDAD – Edad
    Se considera adolescencia 10–19 años.
	
Las siguientes preguntas se realizan a personas mayores a 15 años

P46_NACIDOSVIV – Nº de hijos nacidos vivos
    0 Ninguno (No privado dentro del grupo 10–19)
    >0 Al menos uno (posible privado si año reciente)

P48B_ANO – Año del último nacimiento
    Ventana 2008–2012 para definir "reciente".

Combinaciones (solo mujeres 15–19):
    - Mujer, 15–19 años, P46_NACIDOSVIV > 0 y P48B_ANO ∈ [2008,2012] → (Privado)
    - Mujer, 15–19 años, P46_NACIDOSVIV == 0 
    - Mujer, fuera de 15–19 → (No privado)
    - Hombre → (No privado)
*/

*-------------------------------------------------------------------------
* no se realiza el analisis para casos donde:  P46_NACIDOSVIV==99 & P49B_LUGARPARTO !=9, ya que cuando p46==99, p49==., y no se especifica un lugar de parto
*--------------------------------------------------------------
* Crear variable de privación a nivel individual
*--------------------------------------------------------------
cap drop embarazo_ado_estricto
gen embarazo_ado_estricto = .

* Privación si tuvo su primer hijo hasta los 19 años (embarazo adolescente) y fue en los últimos 5 años
replace embarazo_ado_estricto = 1 if P24_SEXO==1 ///
    & inrange(P25_EDAD,15,19) ///
    & P46_NACIDOSVIV > 0 & P46_NACIDOSVIV <= 98 ///
    & ult5años==1	
replace embarazo_ado_estricto = 1 if P25_EDAD == 20 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO<=2011
	
* No privación si tuvo su primer hijo antes de los 19 años (embarazo adolescente), pero fue hace más de 5 años
replace embarazo_ado_estricto = 0 if P24_SEXO==1 ///
    & inrange(P25_EDAD,15,19) ///
    & P46_NACIDOSVIV > 0 & P46_NACIDOSVIV <= 98 ///
    & ult5años==0
	
*$
* Privación si tuvo su primer hijo hasta los 24 años que era adolescente al momento de su embarazo y fue en los últimos 5 años
***Privación si tiene 24 al momento del Censo pero era adolescente al momento de su último parto: 

replace embarazo_ado_estricto = 1 if P25_EDAD == 24 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO<=2007

replace embarazo_ado_estricto = 0 if P25_EDAD == 24 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO>2007

*&
***Privación si tiene 23 al momento del Censo pero era adolescente al momento de su último parto: 

replace embarazo_ado_estricto = 1 if P25_EDAD == 23 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO<=2008

replace embarazo_ado_estricto = 0 if P25_EDAD == 23 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO>2008

***Privación si tiene 22 al momento del Censo pero era adolescente al momento de su último parto: 

replace embarazo_ado_estricto = 1 if P25_EDAD == 22 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO<=2009

replace embarazo_ado_estricto = 0 if P25_EDAD == 22 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO>2009

***Privación si tiene 21 al momento del Censo pero era adolescente al momento de su último parto (no privacion si no era adolescente al momento del parto) 

replace embarazo_ado_estricto = 1 if P25_EDAD == 21 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO<=2010

replace embarazo_ado_estricto = 0 if P25_EDAD == 21 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO>2010

***Privación si tiene 20 al momento del Censo pero era adolescente al momento de su último parto (no privacion si no era adolescente al momento del parto) 

replace embarazo_ado_estricto = 1 if P25_EDAD == 20 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO<=2011

replace embarazo_ado_estricto = 0 if P25_EDAD == 20 & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 1 & P48B_ANO>2011

* No privación si tuvo su primer hijo entre los 12 a 24 años (embarazo adolescente, ya que si tiene 24 hace 5 años tenia 19); sin embargo, fue hace más de 5 años
replace embarazo_ado_estricto = 0 if inrange(P25_EDAD, 12, 24) & (P46_NACIDOSVIV>0 & P46_NACIDOSVIV<=98) & ult5años == 0

*	
	
* NO PRIVADO: mujer sin hijos
replace embarazo_ado_estricto = 0 if P24_SEXO==1 & P46_NACIDOSVIV == 0

* NO PRIVADO: mujer fuera de 10–24
replace embarazo_ado_estricto = 0 if P24_SEXO==1 & !inrange(P25_EDAD,15,24)
	
** missings
replace embarazo_ado_estricto = . if P46_NACIDOSVIV == 99 
		
* NO PRIVADO: todos los hombres
replace embarazo_ado_estricto = 0 if P24_SEXO==2

tab embarazo_ado_estricto, m

*--------------------------------------------------------------
* Crear indicador a nivel hogar (al menos un miembro privado)
*--------------------------------------------------------------
bys I_BC_VIV: egen embarazo_ado_hogar_estricto = ///
    max(embarazo_ado_estricto)

label var embarazo_ado_hogar_estricto ///
    "Privación: embarazo adolescente (edad al nacer ≤19)"

label values embarazo_ado_hogar_estricto priv_label

tab embarazo_ado_hogar_estricto, m
*---------------------------------------------------------------------------
* 6. EDUCACIÓN: NO ASISTENCIA A CENTRO EDUCATIVO (P36_ASISTE + edad)
*---------------------------------------------------------------------------

/*
P36_ASISTE – ¿Asiste actualmente a escuela/colegio/universidad?
    1 Sí – pública      (No privado si edad 6–19)
    2 Sí – privada      (No privado si edad 6–19)
    3 Sí – de convenio  (No privado si edad 6–19)
    4 No                (Privado si edad 6–19)
    9 Sin especificar   

P25_EDAD – Edad
    Se considera población en edad 6–19 años.

Combinaciones relevantes:
    - Edad ∈ [6,19] y P36_ASISTE ∈ {4,9} → (Privado)
    - Edad ∈ [6,19] y P36_ASISTE ∈ {1,2,3} → (No privado)
    - Edad < 6 o > 19 → (No privado en este indicador)
*/

* Criterio final (nivel individuo):
*   PRIVADO si:
*       - P25_EDAD [6,19] y P36_ASISTE {4}
*   NO PRIVADO si:
*       - P25_EDAD [6,19] y P36_ASISTE {1,2,3}
*       - P25_EDAD < 6 o P25_EDAD > 19
*--------------------------------------------------------------------------

cap drop sin_asistencia_ind
gen sin_asistencia_ind = .
replace sin_asistencia_ind = 1 if inrange(P25_EDAD,6,19) & inlist(P36_ASISTE,4)
replace sin_asistencia_ind = 0 if inrange(P25_EDAD,6,19) & inlist(P36_ASISTE,1,2,3)
replace sin_asistencia_ind = 0 if P25_EDAD<6 | P25_EDAD>19

bys I_BC_VIV: egen sin_asistencia_hogar = max(sin_asistencia_ind)
label var sin_asistencia_hogar "Privación en asistencia educativa (1=privado)"
label values sin_asistencia_hogar priv_label

tab sin_asistencia_hogar, m


********************************************************************************
* DIMENSIÓN: RECURSOS
********************************************************************************
*---------------------------------------------------------------------------
* 7. AGUA POTABLE – (P07)
*---------------------------------------------------------------------------
/*
P07 - Fuente principal del agua que utiliza el hogar

    1 Cañería de red (No privado) - (No privado)
    2 Pileta pública (No privado) - (No privado)
    3 Carro repartidor (Privado) - (Privado)
    4 Pozo o noria con bomba (Privado) - (No privado)
    5 Pozo o noria sin bomba (Privado) - (Privado)
    6 Lluvia, río, vertiente, acequia (Privado) - (Privado)
    7 Lago, laguna, curichi (Privado) - (Privado)
*/

* Criterio:
*   PRIVADO si:
*       - P07 {3,4,5,6,7} y URBRUR == 1
*       - P07 {3,5,6,7} y URBRUR == 2 
*   NO PRIVADO si:
*       - P07 {1,2} y URBRUR == 1
*       - P07 {1,2,4} y URBRUR == 2 
*--------------------------------------------------------------------------
cap drop agua_potable
gen agua_potable = .

replace agua_potable = 1 if inlist(P07,3,4,5,6,7) & URBRUR==1
replace agua_potable = 1 if inlist(P07,3,5,6,7) & URBRUR==2
replace agua_potable = 0 if inlist(P07,1,2) & URBRUR==1
replace agua_potable = 0 if inlist(P07,1,2,4) & URBRUR==2

label var agua_potable "Privación por falta de agua potable (1=privado)"
label values agua_potable priv_label

tab agua_potable, m

*---------------------------------------------------------------------------
* 8. ELECTRICIDAD – (P11_ENERGIA)
*---------------------------------------------------------------------------
/*
Misma P11_ENERGIA, pero:
    1–4 → No privado, excepto:
    5 → Privado (según tu criterio original, aquí se mantuvo como privado)

En tu código original:
    priv_electricidad1 = 1 si P11_ENERGIA == 5
    priv_electricidad1 = 0 si P11_ENERGIA {1,2,3,4}
*/

* Criterio final:
*   PRIVADO si:
*       - P11_ENERGIA == 5
*   NO PRIVADO si:
*       - P11_ENERGIA {1,2,3,4}
*--------------------------------------------------------------------------

cap drop priv_electricidad
gen priv_electricidad = .
replace priv_electricidad = 1 if P11_ENERGIA==5
replace priv_electricidad = 0 if inlist(P11_ENERGIA,1,2,3,4)

label var priv_electricidad "Privación por electricidad ( 1=privado)"
label values priv_electricidad priv_label

tab priv_electricidad, m

*---------------------------------------------------------------------------
* 9. SANEAMIENTO BÁSICO (P10_DESAGUE)
*---------------------------------------------------------------------------
/*

P10_DESAGUE – Tipo de desagüe del baño/letrina
    1 Alcantarillado sanitario (No privado) - (No privado)
    2 Cámara séptica o pozo séptico (Privado) - (No privado)
    3 Pozo ciego (Privado) - (No privado)
    4 A la calle (Privado) - (Privado)
    5 A la quebrada, rio (Privado) - (Privado)
    6 A un lago, laguna, curichi (Privado) - (Privado)
*/

* Criterio final:
*   PRIVADO si: 
*       - P10_DESAGUE {2,3,4,5,6} y URBRUR == 1
*       - P10_DESAGUE {4,5,6} y URBRUR == 2
*   NO PRIVADO si:
*       - P10_DESAGUE {1} y URBRUR == 1
*       - P10_DESAGUE {1,2,3} y URBRUR == 2
*--------------------------------------------------------------------------
cap drop saneamiento
gen saneamiento = .
replace saneamiento = 1 if saneamiento==.

replace saneamiento = 1 if inlist(P10_DESAGUE,2,3,4,5,6) & URBRUR==1
replace saneamiento = 1 if inlist(P10_DESAGUE,4,5,6) & URBRUR==2

replace saneamiento = 0 if inlist(P10_DESAGUE,1) & URBRUR==1
replace saneamiento = 0 if inlist(P10_DESAGUE,1,2,3) & URBRUR==2

label var saneamiento "Privación por falta de saneamiento (1=privado)"
label values saneamiento priv_label

tab saneamiento, m 


*******************************************************************************
* COLAPSAR A NIVEL HOGAR
*******************************************************************************

collapse (max) ///
    analfabetismo_hogar ///
    sin_carnet_hogar ///
    priv_comunicacion ///
    parto_no_salud_hogar ///
    embarazo_ado_hogar_estricto ///
    sin_asistencia_hogar ///
    agua_potable ///
    priv_electricidad ///
    saneamiento ///
    I02_DEPTO ///
    I03_PROV ///
    URBRUR ///
    URBRUR_P ///
    ID_INE_CENSO_MUN, ///
    by(I_BC_VIV)

*-----------------------------------------------------------*
* Renombrar variables 2012 para que coincidan con 2024      *
*-----------------------------------------------------------*
rename analfabetismo_hogar    con_analfabeto_2012
rename sin_carnet_hogar       sin_carnet_2012
rename priv_comunicacion      sin_telefono_2012
rename parto_no_salud_hogar   sin_acceso_a_salud_2012
rename embarazo_ado_hogar_estricto     embarazo_adolescente_2012
rename sin_asistencia_hogar   con_no_estudia_2012
rename agua_potable           sin_agua_potable_2012
rename priv_electricidad      sin_electricidad_2012
rename saneamiento            sin_saneamiento_2012
rename I02_DEPTO              dep_res_cod
rename I03_PROV               prov_cod
rename URBRUR                 urbrur

order con_analfabeto_2012 sin_carnet_2012 sin_telefono_2012 ///
      sin_acceso_a_salud_2012 embarazo_adolescente_2012 ///
      con_no_estudia_2012 sin_agua_potable_2012 ///
      sin_electricidad_2012 sin_saneamiento_2012 ///
      ID_INE_CENSO_MUN urbrur dep_res_cod prov_cod I_BC_VIV URBRUR_P

save "$out\base_vivienda_collapse_2012.dta", replace

export delimited "$out\base_vivienda_collapse_2012.csv", replace delimiter(",")

global indicadores con_analfabeto_2012 sin_carnet_2012 sin_telefono_2012 ///
    sin_acceso_a_salud_2012 embarazo_adolescente_2012 con_no_estudia_2012 ///
    sin_agua_potable_2012 sin_electricidad_2012 sin_saneamiento_2012

egen tag_viv = tag(I_BC_VIV)

egen total_privaciones = rowtotal($indicadores)

label var total_privaciones "Número total de privaciones (0-9)"

tab total_privaciones if tag_viv==1

*******************************************************************************
* CALCULO DEL INDICE DE POBREZA MULTIDIMENSIONAL (IPM)
*******************************************************************************

global indicadores "con_analfabeto_2012 sin_carnet_2012 sin_telefono_2012 sin_acceso_a_salud_2012 embarazo_adolescente_2012 con_no_estudia_2012 sin_agua_potable_2012 sin_electricidad_2012 sin_saneamiento_2012"

foreach var of global indicadores {
    cap drop w_`var'
    gen w_`var' = 1/9
    label var w_`var' "Peso de `var'"
}

*******************************************************************************
* MATRIZ DE PRIVACIONES
*******************************************************************************

foreach var in con_analfabeto_2012 sin_carnet_2012 sin_telefono_2012 sin_acceso_a_salud_2012 embarazo_adolescente_2012 con_no_estudia_2012 sin_agua_potable_2012 sin_electricidad_2012 sin_saneamiento_2012 {
    cap drop g0_w_`var'
    gen g0_w_`var' = `var' * w_`var'
    lab var g0_w_`var' "Privacion ponderada de `var'"
}

*******************************************************************************
* DEFINIR VECTOR DE CONTEO (ci)
*******************************************************************************

egen c_vector = rowtotal(g0_w_*)
lab var c_vector "Vector de conteo"
tab c_vector, m

*******************************************************************************
* CANTIDAD DE POBRES MULTIDIMENSIONALES: MANUAL CON k = 0.33 (3 DIMENSIONES)
*******************************************************************************

* Identificar los hogares pobres multidimensionales
gen _mpi_h = 1    if c_vector >= 0.33 & c_vector != .  /* Punto de corte */
gen _mpi_e = 1    if c_vector >= 0.44 & c_vector != .  /* Punto de corte IPM extremo */

replace _mpi_h = 0 if c_vector < 0.33
count if _mpi_h==1

* Calcular privaciones ponderadas
gen _mpi_m0 = c_vector
replace _mpi_m0 = 0 if _mpi_h == 0

gen _mpi_a = c_vector if _mpi_h == 1

* Calcular la incidencia (H) // corte >=0.33
count if _mpi_h == 1
local q = r(N)
count if c_vector != .
local n = r(N)
local H = (`q' / `n') * 100

* Calcular la incidencia extrema (He) // corte >=0.44
count if _mpi_e == 1
local qe = r(N)
count if c_vector != .
local n = r(N)
local He = (`qe' / `n') * 100

* Calcular la intensidad (A)
summarize _mpi_a
local A = r(mean) * 100

* Calcular el indice de pobreza multidimensional (MPI)
local MPI = (`H' * `A') / 100

* Mostrar resultados
display "--------------------------------------------"
display "Indice de Pobreza Multidimensional (nivel nacional)"
display "--------------------------------------------"
display "Incidencia (H): "    %6.2f `H'   " %"
display "Incidencia (He): "   %6.2f `He'  " %"
display "Intensidad (A): "    %6.2f `A'   " %"
display "MPI (H x A / 100): " %6.3f `MPI'
display "--------------------------------------------"

*******************************************************************************
* GENERACION DE TABLAS: MEDIDAS H, A, M0 (URBANO RURAL)
*******************************************************************************

cap drop _mpi_*

* Identificar hogares pobres multidimensionales
gen _mpi_h = 1 if c_vector >= 0.33 & c_vector != .
replace _mpi_h = 0 if c_vector < 0.33

* Calcular privaciones ponderadas
gen _mpi_m0 = c_vector
replace _mpi_m0 = 0 if _mpi_h == 0

gen _mpi_a = c_vector if _mpi_h == 1

*---------------------------------------------------------------*
* Calculo por area urbana/rural
*---------------------------------------------------------------*
preserve
collapse (count) n_obs     = c_vector ///
         (sum)   sum_pobres = _mpi_h  ///
         (mean)  mean_a     = _mpi_a, by(urbrur)

* Calcular H, A y MPI
gen H   = (sum_pobres / n_obs) * 100
gen A   = mean_a * 100
gen MPI = (H * A) / 100

* Etiquetas de area
label define area 1 "Urbano" 2 "Rural"
label values urbrur area

* Mostrar resultados
display "--------------------------------------------"
display "Indice de Pobreza Multidimensional (por area)"
display "--------------------------------------------"
list urbrur H A MPI, noobs clean
display "--------------------------------------------"

restore

*******************************************************************************
* GENERACION DE TABLAS: MEDIDAS H, A, M0 (POR MUNICIPIOS)
*******************************************************************************

*---------------------------------------------------------------*
* Calcular MPI por municipio con k = 0.33
*---------------------------------------------------------------*
preserve

gen uno = 1

collapse ///
    (mean)  H       = _mpi_h ///
    (mean)  A       = _mpi_a ///
    (count) hogares = uno    ///
    , by(ID_INE_CENSO_MUN)

gen MPI = H * A

label var H       "Incidencia multidimensional (H)"
label var A       "Intensidad (A)"
label var MPI     "Indice de Pobreza Multidimensional (MPI)"
label var hogares "Numero de hogares"

sort ID_INE_CENSO_MUN

save "$out/ipm_municipal_2012.dta", replace
export delimited using "$out/mpi_municipal_2012.csv", replace
export excel using "$out/mpi_municipal_2012.xlsx", replace firstrow(variables)

restore

*******************************************************************************
* PORCENTAJE DE PRIVACIONES POR INDICADOR (POR MUNICIPIOS)
*******************************************************************************

foreach var of global indicadores {
    bys ID_INE_CENSO_MUN: egen total_`var'   = total(`var')
    bys ID_INE_CENSO_MUN: egen total_hogares = total(!missing(`var'))
    gen prop_`var' = (total_`var' / total_hogares) * 100
    label var prop_`var' "Proporcion de hogares con `var' (%)"
    drop total_`var' total_hogares
}

preserve
collapse (mean) prop_*, by(ID_INE_CENSO_MUN)
foreach var of varlist prop_* {
    replace `var' = round(`var', 0.01)
}
sort ID_INE_CENSO_MUN
save "$out\prop_municipal_2012.dta", replace
export delimited using "$out/prop_municipal_2012.csv", replace nolabel
restore

/*
*******************************************************************************
* CONTRIBUCION DE DIMENSIONES Y SUBDIMENSIONES - NIVEL GLOBAL
*******************************************************************************

local indicadores con_analfabeto_2012 sin_carnet_2012 sin_telefono_2012 sin_acceso_a_salud_2012 embarazo_adolescente_2012 con_no_estudia_2012 sin_agua_potable_2012 sin_electricidad_2012 sin_saneamiento_2012

sum _mpi_m0
local M0 = r(mean)

tempfile base
save `base', replace

preserve

postfile contrib str40 indicator contrib_pct using contrib_temp, replace

foreach ind of local indicadores {
    use `base', clear
    gen g0c = g0_w_`ind'
    replace g0c = 0 if _mpi_h == 0
    sum g0c
    local contrib = (r(mean) / `M0') * 100
    post contrib ("`ind'") (`contrib')
}

postclose contrib
restore

use contrib_temp, clear
encode indicator, gen(ind_id)

graph bar (sum) contrib_pct, over(ind_id, label(angle(45))) ///
    stack asyvars ///
    blabel(bar, position(west) format(%4.1f) size(vsmall)) ///
    ytitle("Contribucion al MPI (%)") ///
    title("Contribucion de los indicadores al MPI (Nivel Nacional)", size(medium)) ///
    legend(on) legend(rows(3)) ///
    bar(1, color("239 151 27")) ///
    bar(2, color("246 209 2")) ///
    bar(3, color("31 128 31")) ///
    bar(4, color("246 185 5")) ///
    bar(5, color("104 106 102")) ///
    bar(6, color("18 99 140")) ///
    bar(7, color("92 175 108")) ///
    bar(8, color("31 68 106")) ///
    bar(9, color("81 168 88"))
*/

*******************************************************************************
* NUMERO DE HOGARES CON FALENCIAS EN 4 O MAS DIMENSIONES (DE 9), 2012
*******************************************************************************

use "$out/base_vivienda_collapse_2012", clear

egen num_carencias = rowtotal(con_analfabeto_2012 sin_carnet_2012 sin_telefono_2012 sin_acceso_a_salud_2012 embarazo_adolescente_2012 con_no_estudia_2012 sin_agua_potable_2012 sin_electricidad_2012 sin_saneamiento_2012)

tab num_carencias

cap drop carencias4
gen carencias4 = .
replace carencias4 = 1 if num_carencias >= 4

collapse (sum) carencias4, by(ID_INE_CENSO_MUN)

sort ID_INE_CENSO_MUN
export excel using "$out/numero_carencias_mayor_igual_4_2012.xlsx", replace firstrow(variables)



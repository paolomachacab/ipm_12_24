********************************************************************************
***** SDSN 2025 *****
********************************************************************************

* Organización:	SDSN
* Objetivo:	Generar el indicador de IPM a partir del censo 2012
* Fecha: Octubre, 2025
* Propiedad del código:	Bruna Torrico
* Revisado por:	
* Elaborado por: Bruna Torrico
* Comentarios a: brunatorriale@gmail.com
********************************************************************************
*******************************************************************************
clear all 
set more off
version 17.0
*******************************************************************************

if ("`c(username)'" == "BRUNA") { // Bruna Torrico (laptop)
	global path	"C:\Bruna\sdsn"
	global in 	"$path/_in"
	global out  "$path/_graph"
	global code "$path/_code"
	global tbl	"$path/_tbl"
	global out  "$path/_out"
}


*use "$in/censo_persona_mun_2024.dta"
*------------------------------------------------------------------------------
* merge m:1 i00 using "$in/censo_vivienda_2024.dta"

/*
use "$in/censo_vivienda_2024.dta"
merge 1:m i00 using "$in/censo_persona_2024.dta"
	// mismo resultado
	// Not matched                       840,062

tab v02_condocup if _merge == 1	
	// Total |                           840,062 
	// Ninguna de estas viviendas tiene personas censadas asociadas en la base de personas, por eso no hicieron match.
*/

* keep if _merge == 3

* Solo nos quedamos con viviendas particulares o destinadas a la vivida
* keep if inrange(v01_tipoviv,1,6)
	// 11,134,130 individuos en total
	
* save "$out/personas_vivienda_censo_2024", replace

use "$out/personas_vivienda_censo_2024"

*******************************************************************************
* Creación de subgrupos poblacionales
*******************************************************************************
*Jefe de hogar por sexo
cap drop jefe_sexo
gen jefe_sexo=.
replace jefe_sexo=1 if p24_parentes==1 & p25_sexo==1  // mujer
replace jefe_sexo=0 if p24_parentes==1 & p25_sexo==2  // hombre

cap drop jefe_hogar
bysort i00: egen jefe_hogar = max(jefe_sexo)

	// crea 5,779 missings, porque hay esa cantidad de viviendas sin un jefe de hogar
	
/*. tab v02_condocup jefe_hogar,m

v02_condoc |            jefe_hogar
        up |         0          1          . |     Total
-----------+---------------------------------+----------
         0 |         0          0      5,779 |     5,779 
         1 | 7,032,638  4,095,713          0 |11,128,351 
-----------+---------------------------------+----------
     Total | 7,032,638  4,095,713      5,779 |11,134,130   */
	 
*-----------------------
*Jefe de hogar indigena 
cap drop jefe_indigena
gen jefe_indigena=.
replace jefe_indigena=1 if p24_parentes==1 & p32_pueblo_per==1   // indigena
replace jefe_indigena=0 if p24_parentes==1 & p32_pueblo_per==2   // no indigena

cap drop jefe_indigena_v
bysort i00: egen jefe_indigena_v = max(jefe_indigena)

tab jefe_indigena_v,m
*-----------------------

*Jefe de hogar indigena por sexo
cap drop jefe_indigena_s
gen jefe_indigena_s=.
replace jefe_indigena_s=1 if p24_parentes==1 & p32_pueblo_per==1 & p25_sexo==1  // mujer
replace jefe_indigena_s=0 if p24_parentes==1 & p32_pueblo_per==1 & p25_sexo==2  // hombre

cap drop jefe_indigena_s_v
bysort i00: egen jefe_indigena_s_v = max(jefe_indigena_s)
*-----------------------

*Jefe de hogar no indigena por sexo
cap drop jefe_no_indigena
gen jefe_no_indigena=.
replace jefe_no_indigena=1 if p24_parentes==1 & p32_pueblo_per==2 & p25_sexo==1  // mujer
replace jefe_no_indigena=0 if p24_parentes==1 & p32_pueblo_per==2 & p25_sexo==2  // hombre

cap drop jefe_no_indigena_v
bysort i00: egen jefe_no_indigena_v = max(jefe_no_indigena)
*-----------------------

*Hogar con al menos un miembro del hogar discapacitado
cap drop discapacitado
gen discapacitado=.
replace discapacitado=1 if p42_discap ==1 // discapacitado
replace discapacitado=0 if p42_discap ==2 // no discapacitado

cap drop discapacitado_v
bysort i00: egen discapacitado_v = max(discapacitado) // sin missings

*******************************************************************************
* Dimensión: Poder y voz
*******************************************************************************
*------------------------------------------------------------------------------
*Analfabetismo
*-------------------------------------------------------------------------------
*P40_LEE  40.   Sabe leer y escribir

* 1) Variable individual: 1 si persona tiene 15+ años y no sabe leer
cap drop analfabetismo_ind
gen analfabetismo_ind = (p26_edad >= 15 & p40_lee == 2)

	// 336,157 privados

* 2) Variable a nivel hogar: 1 si al menos una persona del hogar tiene analfabetismo_ind==1
cap drop analfabetismo_hogar
bysort i00: egen analfabetismo_hogar = max(analfabetismo_ind)

	// 990,120 privados
	
* Crear labels
label var analfabetismo_hogar "Privación por analfabetismo (1=privado)"
label define priv_label 0 "No privación" 1 "Privación"
label values analfabetismo_hogar priv_label

* Revisar la tabulación
tab analfabetismo_hogar,m // sin missings 
	*------------------------------------------------------------------------------
*Documento de identidad
*-------------------------------------------------------------------------------
*P29_CI  29.   Tiene o tuvo cédula de identidad boliviana

* 1) Variable individual: 1 si persona tiene 6+ años y no tiene carnet de identidad
cap drop sin_carnet_ind
gen sin_carnet_ind = (p26_edad >= 6 & p29_ci == 2) 
	// 3:Cédula Boliviana de extranjero
	
	// 31,844 privados

* 2) Variable a nivel hogar: 1 si al menos una persona del hogar tiene analfabetismo_ind==1
cap drop sin_carnet_hogar
bysort i00: egen sin_carnet_hogar = max(sin_carnet_ind)

	// 105,409 privados

* Crear labels
label var sin_carnet_hogar "Privación en documento de identidad (1=privado)"
label define carnet_label 0 "No privación" 1 "Privación"
label values sin_carnet_hogar carnet_label

* Revisar la tabulación
tab sin_carnet_hogar,m //sin missings 

/* . tab sin_carnet_hogar residente,m

 Privación en |
 documento de |
    identidad |       residente
  (1=privado) |         0          1 |     Total
--------------+----------------------+----------
 No privación |    94,486 10,934,235 |11,028,721 
    Privación |     5,896     99,513 |   105,409 
--------------+----------------------+----------
        Total |   100,382 11,033,748 |11,134,130  */

*------------------------------------------------------------------------------
*Comunicación ()
*-------------------------------------------------------------------------------
*sección de vivienda
*V19D_CELULAR   19.4. Su hogar tiene: Teléfono celular
*V19H_TELFIJO 19.8. Su hogar tiene: Servicio de telefonía fija

cap drop priv_comunicacion
gen priv_comunicacion = .
replace priv_comunicacion = 1 if ///
(v19d_celular == 2 & inlist(v19h_telfijo,2,9,.)) | ///
(v19h_telfijo == 2 & inlist(v19d_celular,2,9,.))

replace priv_comunicacion = 0 if v19d_celular == 1 | v19h_telfijo == 1
replace priv_comunicacion = . if inlist(v19d_celular,9,.) & inlist(v19h_telfijo,9,.)

* Crear labels
label var priv_comunicacion "Privación por analfabetismo (1=privado)"
label define priv_comunicacion_label 0 "No privación" 1 "Privación"
label values priv_comunicacion priv_comunicacion_label

* Revisar la tabulación
tab priv_comunicacion,m // contiene missings

	// 816,930 privados

*******************************************************************************
* Dimensión: Oportunidades y elección
*******************************************************************************
*------------------------------------------------------------------------------
*Salud (parto no atendido en un centro de salud)
*------------------------------------------------------------------------------

/* - p59_mef 1,2,3, atención de médicos calificados = 652 899 */
*---------------------------	

mvdecode p30a_public p30b_caja p30c_privad p30d_atedom p30e_tradic p30f_autome p30g_casera, mv(9=.)


* 1. Varible que identifica la mujer que tuvo un hijo o más y dio a luz  hasta la fecha del censo
cap drop parto
gen parto = . 

* Mujeres mayores a 12 que tuvieron un parto 
replace parto = 1 if p26_edad >= 12 & p54_hvtot >= 1 & p25_sexo == 1

* Mujeres mayores a 12 que no tuvieron un parto 
replace parto = 0 if p26_edad >= 12 & p54_hvtot == 0 & p25_sexo == 1

* Casos especiales: respondió "omito" pero indicó número de hijos
replace parto = 1 if p54_hvtot == 98 & p25_sexo == 1

tab parto 

	// 3,462,997 mujeres tuvieron un parto con un hijo nacido vivo o muerto :(
*---------------------------	
	
* 2. Parto no atendido por personal calificado (según definiciones del INE) 
cap drop parto_no_calif_ind 
gen parto_no_calif_ind = . //* Los códigos 9 (sin especificar) permanecen como missing
replace parto_no_calif_ind = 1 if parto == 1 & inlist(p59_mef,4,5,6,7,8)
replace parto_no_calif_ind = 0 if parto == 1 & inlist(p59_mef,1,2,3)

tab parto_no_calif_ind 

	// 644,681 partos realizados por personal de salud calificado 
	
	// 54,713 privadas de personal de salud calificado en el parto 
	
/* . tab parto parto_no_calif_ind,m

           |        parto_no_calif_ind
     parto |         0          1          . |     Total
-----------+---------------------------------+----------
         0 |         0          0    988,633 |   988,633 
         1 |   644,681     54,713  2,763,603 | 3,462,997 
         . |         0          0  6,682,500 | 6,682,500 
-----------+---------------------------------+----------
     Total |   644,681     54,713 10,434,736 |11,134,130   */
	 
	
* Variable a nivel de hogar 
cap drop parto_no_salud_hogar 
bysort i00: egen parto_no_salud_hogar = max(parto_no_calif_ind) 

	// 258,871 privados de personal de salud en el parto anivel hogar 
	
*---------------------------	

/* 3. Varible de centro de salud mide estrictamente el lugar del parto, a donde acude la mujer cuando tiene problemas de salud*/

cap drop centro_salud
gen centro_salud = .

* Marcar como 0 si la mujer (con parto) acude al menos a un centro formal independientemente de que acuda a uno alternativo
replace centro_salud = 0 if parto == 1 & ///
 (p30a_public == 1 | p30b_caja == 1 | p30c_privad == 1) 
	
	// 3,140,875  no privadas - 0
	
* Marcar 1 para quienes NO fueron a un centro formal
replace centro_salud = 1 if parto == 1 & ///
(p30a_public != 1 & p30b_caja != 1 & p30c_privad != 1)

	// 322,122 privadas - 1	
	
* Variable a nivel de hogar 
cap drop centro_salud_hogar
bysort i00: egen centro_salud_hogar = max(centro_salud) 
	
	// 1,029,307 privados de atención en un centro de salud /*. 

tab centro_salud parto_no_calif_ind,m 

/* tab centro_salud parto_no_calif_ind,m 

centro_sal |        parto_no_calif_ind
        ud |         0          1          . |     Total
-----------+---------------------------------+----------
         0 |   611,239     45,188  2,484,448 | 3,140,875 
         1 |    33,442      9,525    279,155 |   322,122 
         . |         0          0  7,671,133 | 7,671,133 
-----------+---------------------------------+----------
     Total |   644,681     54,713 10,434,736 |11,134,130   */
	 *------------------------------------------------------------------------------ 

* Variable proxi de atención en un centro de salud en el parto 

cap drop proxi_centro_salud
gen proxi_centro_salud=. 
* 0 = no privación (parto atendido por personal calificado o en centro de salud) 
replace proxi_centro_salud = 0 if parto==1 & (centro_salud==0 | parto_no_calif_ind==0)
 * 1 = privación (parto sin atención institucional ni personal calificado) 
replace proxi_centro_salud = 1 if parto==1 & (centro_salud==1 | parto_no_calif_ind==1) 

replace proxi_centro_salud=0 if parto==0
	// 367,310 privadas que no se atienden en un centro de salud ni se atendieron por personal calificado 
	
* Variable a nivel de hogar 
cap drop proxi_centro_salud_hogar 
bysort i00: egen proxi_centro_salud_hogar = max(proxi_centro_salud) 
	
	//  1,233,517 privados de atención en un centro de salud o atencion especializada

* Crear labels
label var proxi_centro_salud "Privación por analfabetismo (1=privado)"
label define proxi_centro_salud_label 0 "No privación" 1 "Privación"
label values proxi_centro_salud proxi_centro_salud_label

* Revisar la tabulación
tab proxi_centro_salud,m  // con missings

	
*-------------------------------------------------------------------------------
*Embarazo adolescente
*------------------------------------------------------------------------------

* 1. Crear variable individual de embarazo adolescente reciente
cap drop embarazo_ado_reciente
gen embarazo_ado_reciente = 0
replace embarazo_ado_reciente = 1 if p54_hvtot >= 1 ///
    & p56_edadmad < 20 ///
    & (p26_edad - p56_edadmad) <= 5

	// 78,512 privadas
	
* 2. Colapsar a nivel hogar: al menos un caso en el hogar
bysort i00: egen embarazo_ado_hogar = max(embarazo_ado_reciente)

	// 349,507 privados 

* Crear labels
label var embarazo_ado_hogar "Privación por analfabetismo (1=privado)"
label define embarazo_ado_hogar_label 0 "No privación" 1 "Privación"
label values embarazo_ado_hogar embarazo_ado_hogar_label

* Revisar la tabulación
tab embarazo_ado_hogar,m // sin missings

	// 349,507 privados 
*-------------------------------------------------------------------------------
*Educación
*-------------------------------------------------------------------------------
*P38_ASISTE  38. Actualmente, asiste como estudiante a:
*ASISTE      Asistencia educativa (residentes en el país y que respondieron a la pregunta)

/* verificar la creacion de la variable:ASISTE
cap drop residente
gen residente = inlist(p36_lugres, 1, 2)
*Crear variable de no asistencia educativa
cap drop sin_asistencia_ind
gen sin_asistencia_ind = .
replace sin_asistencia_ind = 1 if p26_edad >= 6 & p26_edad <= 19 & residente == 1 & p38_asiste == 8
replace sin_asistencia_ind = 0 if p26_edad >= 6 & p26_edad <= 19 & residente == 1 & inlist(p38_asiste, 1,2,3,4,5,6,7)

tab p38_asiste if p26_edad >=6 & p26_edad <=19
tab p38_asiste residente if p26_edad >=6 & p26_edad <=19
*/

* variable excluyendo residentes
*-------------------------------
* 1) Variable individual: 1 si persona tiene 6-19 años y no asiste a la escuela
cap drop sin_asistencia_ind
gen sin_asistencia_ind = (p26_edad >= 6 & p26_edad <= 19 & asiste == 2) 
	
	// 238,678 privados residentes
		
* 2) Variable a nivel hogar: 1 si al menos una persona del hogar tiene analfabetismo_ind==1
cap drop sin_asistencia_hogar
bysort i00: egen sin_asistencia_hogar = max(sin_asistencia_ind)

	// 969,392 privados

* Crear labels
label var sin_asistencia_hogar "Privación por analfabetismo (1=privado)"
label define sin_asistencia_hogar_label 0 "No privación" 1 "Privación"
label values sin_asistencia_hogar sin_asistencia_hogar_label

* Revisar la tabulación
tab sin_asistencia_hogar,m // sin missings 
	
* variable incluyendo residentes
*-------------------------------
cap drop sin_asistencia
gen sin_asistencia = .
replace sin_asistencia = 1 if inrange(p26_edad, 6, 19) & p38_asiste == 8
replace sin_asistencia = 0 if inrange(p26_edad, 6, 19) & inlist(p38_asiste,1,2,3,4,5,6,7)

replace sin_asistencia = 0 if (p26_edad < 6 | p26_edad > 19) | inlist(p38_asiste,9,.)

cap drop asistencia_hogar
egen asistencia_hogar = max(cond(sin_asistencia==., 0, sin_asistencia)), by(i00)

* Crear labels
label var asistencia_hogar "Privación por analfabetismo (1=privado)"
label define asistencia_hogar_label 0 "No privación" 1 "Privación"
label values asistencia_hogar asistencia_hogar_label

* Revisar la tabulación
tab asistencia_hogar,m // sin missings

	// 862,664 privados

*******************************************************************************
* Dimensión: Recursos
*******************************************************************************
*------------------------------------------------------------------------------
*Agua potable
*-------------------------------------------------------------------------------
*V07_AGUAPRO  7. Principalmente, el agua que usan en la vivienda proviene de:
*V08_AGUADIST 8. El agua que usan en la vivienda se distribuye:

/*
"1 Cañería de red							No privado
2 Pileta pública							No privado
3 Cosecha de agua de lluvia					No privado
4 Pozo excavado o perforado con bomba		No privado	
5 Pozo no protegido o sin bomba				Privado
6 Manantial o vertiente protegida			No privado
7 Rio, acequia o vertiente no protegida		Privado
8 Carro repartidor (aguatero)				No privado
9 Otro"										Privado
*/	
cap drop agua_no_mejorada	
gen	agua_no_mejorada = 1 if v07_aguapro==5 | v07_aguapro==7  | v07_aguapro==9 
					 
replace agua_no_mejorada = 0 if v07_aguapro==1 | v07_aguapro==2 ///
| v07_aguapro==3 | v07_aguapro==4 | v07_aguapro==6 | v07_aguapro==8 

/*
1	Por cañería dentro de la vivienda		No privado
2	Por cañería fuera de la vivienda, 
	pero dentro del lote o terreno			No privado
3	No se distribuye por cañería			Privado
*/
cap drop mejorada	

gen mejorada = 1 if v08_aguadist==3
replace mejorada = 0 if v08_aguadist==1 | v08_aguadist==2

*------------------------------
* Creación con una sola variable
cap drop agua_potable
gen agua_potable=.
replace agua_potable=1 if v07_aguapro==5 | v07_aguapro==7  | v07_aguapro==9
replace agua_potable = 0 if v07_aguapro==1 | v07_aguapro==2 ///
| v07_aguapro==3 | v07_aguapro==4 | v07_aguapro==6 | v07_aguapro==8 

* Crear labels
label var agua_potable "Privación por falta de agua potable (1=privado)"
label define agua_potable_label 0 "No privación" 1 "Privación"
label values agua_potable agua_potable_label

* Revisar la tabulación
tab agua_potable,m // sin missings

	// 894,987 privados 

*-------------------------------------------------------------------------------
*Electricidad
*-------------------------------------------------------------------------------
*V09_ENERGIA   9. De donde proviene la energía eléctrica que usan en la vivienda
cap drop priv_electricidad

gen priv_electricidad = .
replace priv_electricidad = 1 if inlist(v09_energia,4,5)
replace priv_electricidad = 0 if inlist(v09_energia,1,2,3)
	
* Crear labels
label var priv_electricidad "Privación por falta de electricidad (1=privado)"
label define priv_electricidad_label 0 "No privación" 1 "Privación"
label values priv_electricidad priv_electricidad_label

* Revisar la tabulación
tab priv_electricidad,m // sin missings

	// 932,164 privados

*-------------------------------------------------------------------------------
*Saneamiento básico
*-------------------------------------------------------------------------------
*V15_SERVSAN   15. Tienen, baño o letrina
*V16_DESAGUE   16. El baño o letrina tiene desagüe:

/*
1	Sí, usado solo por su hogar
2	Sí, compartido con otros hogares
3	No tiene
*/

/*
1	A la red de alcantarillado
2	A una cámara séptica
3	A un pozo ciego
4	A un pozo de absorción
5	A la superficie (calle, quebrada o río)
6	Es baño ecológico
*/

* Variable de saneamiento básico privado
cap drop saneamiento
gen saneamiento = .

* 1 = acceso  
replace saneamiento = 0 if inlist(v16_desague,1,2) 
* 0 = privación (no tiene)
replace saneamiento = 1 if v16_desague==3

* Crear labels
label var saneamiento "Privación por falta de saneamiento básico (1=privado)"
label define saneamiento_label 0 "No privación" 1 "Privación"
label values saneamiento saneamiento_privado_label

* Revisar la tabulación
tab saneamiento,m // con missings

*******************************************************************************

*Guardar copia de respaldo
save "$out/base_individual_original", replace

* Crear una observación a nivel de vivienda
collapse (max) jefe_hogar jefe_indigena_v jefe_indigena_s_v jefe_no_indigena_v discapacitado_v analfabetismo_hogar sin_carnet_hogar priv_comunicacion proxi_centro_salud embarazo_ado_hogar asistencia_hogar agua_potable priv_electricidad saneamiento, by(i00)

exit

* Crear labels - analfabetismo
label var analfabetismo_hogar "Privación por analfabetismo (1=privado)"
label define priv_v_label 0 "No privación" 1 "Privación"
label values analfabetismo_hogar priv_v_label

tab analfabetismo_hogar,m
	//	302,489 viviendas privadas
	
* Crear labels - sin_carnet
label var sin_carnet_hogar "Privación en documento de identidad (1=privado)"
label define carnet_v_label 0 "No privación" 1 "Privación"
label values sin_carnet_hogar carnet_v_label

tab sin_carnet_hogar,m

*-------------
* Crear labels jefe_hogar
label var jefe_hogar "Hogar según sexo del jefe de hogar"
label define jefe_hogar_label 0 "Hombre" 1 "Mujer"
label values jefe_hogar jefe_hogar_label

tab jefe_hogar,m

* Crear labels jefe_indigena_v
label var jefe_indigena_v "Hogar según autoidentificación etnica del jefe de hogar"
label define jefe_indigena_v_label 0 "No indigena" 1 "Indigena"
label values jefe_indigena_v jefe_indigena_v_label

tab jefe_indigena_v,m

* Crear labels jefe_indigena_s_v
label var jefe_indigena_v "Hogar según autoidentificación etnica y sexo del jefe de hogar"
label define jefe_indigena_s_v_label 0 0 "Hombre" 1 "Mujer"
label values jefe_indigena_s_v jefe_indigena_s_v_label

tab jefe_indigena_s_v,m

* Crear labels jefe_no_indigena_v
label var jefe_no_indigena_v "Hogar según autoidentificación etnica y sexo del jefe de hogar"
label define jefe_no_indigena_v_label 0 0 "Hombre" 1 "Mujer"
label values jefe_no_indigena_v jefe_no_indigena_v_label

tab jefe_no_indigena_v,m

* Crear labels discapacitado_v
label var discapacitado_v "Hogar según autoidentificación etnica y sexo del jefe de hogar"
label define discapacitado_v_label 0 "No discapacitado" 1 "Discapacitado"
label values discapacitado_v discapacitado_v_label

tab discapacitado_v,m


 
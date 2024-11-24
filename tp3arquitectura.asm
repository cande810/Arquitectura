		.macro leer_entero
		li $v0,5
		syscall
		.end_macro

		.macro imprimir_etiqueta (%etiqueta)
		la $a0, %etiqueta
		li $v0, 4
		syscall
		.end_macro

		.macro terminar
		li $v0,10
		syscall
		.end_macro	

		.macro imprimir_error (%error)
		imprimir_etiqueta(error)
		li $a0, %error
		li $v0, 1
		syscall
		imprimir_etiqueta(retorno)
		.end_macro

.data
slist:  .word 0 
cclist: .word 0 	# Puntero a lista 
wclist: .word 0     # Puntero a actual elemento de lista
schedv: .space 32
noenc:.asciiz "No encontrado \n"
menu:   .ascii "Colecciones de objetos categorizados\n"
        .ascii "====================================\n"
        .ascii "1-Nueva categoría\n"
        .ascii "2-Siguiente categoría\n"
        .ascii "3-Categoría anterior\n"
        .ascii "4-Listar categorías\n"
        .ascii "5-Borrar categoría actual\n"
        .ascii "6-Anexar objeto a la categoría actual\n"
        .ascii "7-Listar objetos de la categoría\n"
        .ascii "8-Borrar objeto de la categoría\n"
        .ascii "0-Salir\n"
        .asciiz "Ingrese la opción deseada: "
error:  .asciiz "Error: "
retorno:.asciiz "\n"
nombreCat:.asciiz "\nIngrese el nombre de una categoría: "
selCat: .asciiz "\nSe ha seleccionado la categoría:"
idObj:  .asciiz "\nIngrese el ID del objeto a eliminar: "
nombreObj:.asciiz "\nIngrese el nombre de un objeto: "
exito:.asciiz "La operación se realizó con éxito\n\n"
espacio:.asciiz "  "
indicador:.asciiz "> "
puntoespacio: .ascii ". "

.text
principal:
    # inicialización del vector de planificador
    la $t0, schedv
    la $t1, nueva_categoria
    sw $t1, 0($t0)
    la $t1, siguiente_categoria
    sw $t1, 4($t0)
    la $t1, categoria_anterior
    sw $t1, 8($t0)
    la $t1, listar_categorias
    sw $t1, 12($t0)
    la $t1, borrar_categoria_actual
    sw $t1, 16($t0)
    la $t1, nuevo_objeto
    sw $t1, 20($t0)
    la $t1, listar_objetos
    sw $t1, 24($t0)
    la $t1, borrar_objeto
    sw $t1, 28($t0)
    jal bucle_principal         # Salta al bucle principal

#---------------- PRINCIPAL
bucle_principal:
    # mostrar menú
    jal mostrar_menu
    beqz $v0, finalizar_principal  # Si la opción es 0, termina el programa
    addi $v0, $v0, -1       # Decrementar opción del menú
    move $t6, $v0           # Opción elegida
    sll $v0, $v0, 2         # Multiplicar opción del menú por 4
    la $t0, schedv          
    add $t0, $t0, $v0       
    lw $t1, ($t0)
    la $ra, retorno_principal  # Guardar dirección de retorno
    jr $t1                   # Llamar a subrutina del menú

retorno_principal:
    j bucle_principal       
finalizar_principal:
    terminar

#---------------- MENÚ
mostrar_menu:
    imprimir_etiqueta(menu)
    leer_entero
    # Si opción inválida ir a L1
    bgt $v0, 8, menu_mostrar_L1    # Si el valor ingresado es <0 o >8
    bltz $v0, menu_mostrar_L1
    # De lo contrario, retornar
    jr $ra
    # Imprimir error 101 y reintentar
menu_mostrar_L1:
    imprimir_error(101)
    j mostrar_menu

#---------------- CATEGORÍAS
# Crear una categoría
nueva_categoria:
    addiu $sp, $sp, -4
    sw $ra, 4($sp)       # Preservar $ra
    la $a0, nombreCat    # Input del nombre de la categoría
    jal getblock
    move $a2, $v0        # $a2 = *char al nombre de la categoría
    la $a0, cclist       # $a0 = lista
    li $a1, 0            # $a1 = NULL
    jal agregar_nodo
    lw $t0, wclist
    bnez $t0, fin_nueva_categoria
    sw $v0, wclist       # Actualizar lista de trabajo si estaba NULL
fin_nueva_categoria:
    li $v0, 0            # Retornar éxito
    lw $ra, 4($sp)
    addi $sp, $sp, 4
    jr $ra

# Avanzar a la siguiente categoría
siguiente_categoria:
    lw $t2, wclist
    beqz $t2, e201
    lw $t3, ($t2)
    lw $t4, 12($t2)
    beq $t3, $t4, e202
    lw $t0, wclist       # Puntero en la lista actual
    lw $t1, 12($t0)      # Mover al final de la categoría (próxima categoría)
    sw $t1, wclist
    jr $ra

# Retroceder a la categoría anterior
categoria_anterior:
    lw $t3, wclist
    beqz $t3, e201
    lw $t3, ($t2)
    lw $t4, 12($t2)
    beq $t3, $t4, e202
    lw $t0, wclist
    lw $t0, ($t0)
    sw $t0, wclist
    jr $ra

# Listar todas las categorías
listar_categorias:
    lw $t3, wclist       # Puntero a la categoría actual
    lw $t1, cclist       
    lw $t2, cclist       # Punteros iniciales    
    
    bucle_listado:
    beqz $t3, e301       # Puntero = NULL? Entonces error 301
    beq $t1, $t3, nodo_actual
    j nodo_no_actual

    nodo_actual:     # Imprimir "> "
    la $a0, indicador
    li $v0, 4        # "> "
    syscall
    j listado_final

    nodo_no_actual:  # Imprimir "  "
    la $a0, espacio
    li $v0, 4        
    syscall
    j listado_final

    listado_final:
    lw $a0, 8($t1)
    li $v0, 4
    syscall
    lw $t1, 12($t1)
    beq $t2, $t1, bucle_principal
    j bucle_listado

borrar_categoria_actual:
    addi $sp, $sp, -4
    sw $ra, 4($sp)
    lw $t1, wclist
    beqz $t1, e401    # Busca que exista categoría

    lw $t1, 4($t1)

    bucle_borrado:
    beqz $t1, borrar_categoria_final    # Busca que exista un objeto
    lw $a0, wclist
    la $a1, 4($a0)
    lw $a0, 4($a0)

    jal eliminar_nodo
    lw $t1, wclist
    lw $t1, 4($t1)
    j bucle_borrado

    borrar_categoria_final:
    lw $a0, wclist
    la $a1, cclist

    jal eliminar_nodo

    lw $t0, cclist
    sw $t0, wclist

    lw $ra, 4($sp)
    addi $sp, $sp, 4
    jr $ra
#---------------- OBJETOS
nuevo_objeto:
    addi $sp, $sp, -4
    sw $ra, 4($sp)       # Guarda $ra en la pila
    la $a0, nombreObj    # Imprime mensaje
    jal getblock         # Llama getblock
    move $a2, $v0        # $a2 = *char al nombre del objeto
    
    lw $t6, wclist       
    move $a0, $t6         # Cargar la dirección de la categoría donde se creará el objeto
    addi $a0, $a0, 4      # Posición en el bloque para poner el número (ID)
    
    jal ultimo_id         # Pasar la posición del ID 
    jal agregar_nodo      # Agregar nodo

fin_nuevo_objeto:
    li $v0, 0            # Retornar éxito
    lw $ra, 4($sp)
    addi $sp, $sp, 4
    j principal

void_id: 
    li $a1, 0
    addi $a1, $a1, 1
    jr $ra

ultimo_id:
    lw $a1, ($a0)
    beqz $a1, void_id    # Si está vacía = 1.
    lw $a1, ($a1)
    lw $a1, 4($a1)
    addi $a1, $a1, 1
    jr $ra

listar_objetos:
    lw $t1, wclist       # Cargar puntero del bloque actual
    beqz $t1, e601
    addi $t1, $t1, 4     # Mover puntero a la posición de la dirección de los bloques
    beqz $t1, e602
    lw $t1, ($t1)        # $a1 movil
    move $t2, $t1        # $a2 fijo
    beqz $t1, e601       # Si no hay objetos, salta al error 601
    
    bucle_objeto:
    lw $a0, 4($t1)            # Imprimir ID
    li $v0, 1     
    syscall
    la $a0, puntoespacio      # Imprimir ". "
    li $v0, 4     
    syscall
    final_objeto:
    lw $a0, 8($t1)            # Imprimir nombre del objeto
    li $v0, 4
    syscall

    lw $t1, 12($t1)           
    beq $t1, $t2, bucle_principal
    j bucle_objeto

borrar_objeto:
    lw $a1, wclist          # Categoría actual       
    beqz $a1, e701
    la $a0, idObj           # Ingrese la ID
    li $v0, 4
    syscall
    leer_entero
    move $t3, $v0           # ID elegida
    lw $a0, 4($a1)    
    la $a1, 4($a1)
    move  $t2, $a0          # Copia de esta dirección

    bucle_eliminar:
        lw $t4, 4($t2)           # Cargar ID del bloque en $t8
        beq $t3, $t4, encontrada # Si encuentra la ID, salta y elimina
        lw $t2, 12($t2)          # Avanza al siguiente bloque
        beq $a0, $t2, no_encontrado # Si da toda la vuelta y no encuentra, error y vuelve a principal
        j bucle_eliminar

encontrada: 
        move $a0, $t2
        jal eliminar_nodo
        imprimir_etiqueta(exito)
        j bucle_principal

no_encontrado: 
        imprimir_etiqueta(noenc)
        j bucle_principal

#---------------- NODOS
# a0: dirección de lista (puntero a la lista), clist o wlist
# a1: NULL si es categoría o ID si es objeto, 4(lista)
# a2: dirección devuelta por getblock
# v0: dirección del nodo agregado
agregar_nodo:
    addi $sp, $sp, -8
    sw $ra, 8($sp)
    sw $a0, 4($sp)
    jal smalloc
    sw $a1, 4($v0) # set node content
    sw $a2, 8($v0)
    lw $a0, 4($sp)
    lw $t0, ($a0) # first node address
    beqz $t0, agregar_nodo_lista_vacia
agregar_nodo_al_final:
    lw $t1, ($t0) # last node address
    # update prev and next pointers of new node
    sw $t1, 0($v0)
    sw $t0, 12($v0)
    # update prev and first node to new node
    sw $v0, 12($t1)
    sw $v0, 0($t0)
    j salida_agregar_nodo
agregar_nodo_lista_vacia:
    sw $v0, ($a0)
    sw $v0, 0($v0)
    sw $v0, 12($v0)
salida_agregar_nodo:
    lw $ra, 8($sp)
    addi $sp, $sp, 8
    jr $ra

# Eliminar un NODO
# a0: dirección del nodo a eliminar
# a1: dirección de la lista donde se elimina el nodo
eliminar_nodo:
    addi $sp, $sp, -8
    sw $ra, 8($sp)
    sw $a0, 4($sp)
    lw $a0, 8($a0) # Obtener dirección del bloque
    jal sfree # liberar bloque
    lw $a0, 4($sp) # restaurar argumento a0
    lw $t0, 12($a0) # obtener dirección del siguiente nodo del nodo a0
    beq $a0, $t0, eliminar_nodo_punto_a_sí_mismo
    lw $t1, 0($a0) # obtener dirección del nodo anterior
    sw $t1, 0($t0)
    sw $t0, 12($t1)
    lw $t1, 0($a1) # obtener dirección del primer nodo nuevamente
    bne $a0, $t1, salida_eliminar_nodo
    sw $t0, ($a1) # lista apunta al siguiente nodo
    j salida_eliminar_nodo
eliminar_nodo_punto_a_sí_mismo:
    sw $zero, ($a1) # solo un nodo
salida_eliminar_nodo:
    jal sfree
    lw $ra, 8($sp)
    addi $sp, $sp, 8
    jr $ra

# a0: mensaje a preguntar
# v0: dirección del bloque asignado con cadena
getblock:
    addi $sp, $sp, -4
    sw $ra, 4($sp)
    li $v0, 4
    syscall
    jal smalloc
    move $a0, $v0
    li $a1, 16
    li $v0, 8
    syscall
    move $v0, $a0
    lw $ra, 4($sp)
    addi $sp, $sp, 4
    jr $ra

#---------------- UTILIDADES
smalloc:
    lw $t0, slist
    beqz $t0, sbrk
    move $v0, $t0
    lw $t0, 12($t0)
    sw $t0, slist
    jr $ra
sbrk:
    li $a0, 16 # tamaño del nodo fijo 4 palabras
    li $v0, 9
    syscall # devolver dirección del nodo en v0
    jr $ra
sfree:
    lw $t0, slist
    sw $t0, 12($a0)
    sw $a0, slist # dirección del nodo en lista no utilizada
    jr $ra

#-------------------- ERRORES
e202: 
    imprimir_error(202)
    j bucle_principal

e201: 
    imprimir_error(201)
    j bucle_principal

e301: 
    imprimir_error(301)
    j bucle_principal     

e401: 
    imprimir_error(401)
    j bucle_principal

e601:
    imprimir_error(601)
    j bucle_principal

e602:
    imprimir_error(602)
    j bucle_principal

e701:
    imprimir_error(701)
    j bucle_principal

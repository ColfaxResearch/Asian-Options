CXX = mpiicpc
CXXFLAGS=-qopenmp -mkl
CPUFLAGS = $(CXXFLAGS) -xhost
MICFLAGS = $(CXXFLAGS) -mmic
OPTFLAGS = -qopt-report -qopt-report-file=$@.optrpt

CPUOBJECTS = main.o workdistribution.o pricing.o 
MICOBJECTS = main.oMIC workdistribution.oMIC pricing.oMIC 

TARGET=app
MICTARGET=app-MIC


.SUFFIXES: .o .cc .oMIC

all: $(TARGET) $(MICTARGET) instructions

app: $(CPUOBJECTS)
	$(info )
	$(info Linking the CPU executable:)
	$(CXX) $(CPUFLAGS) -o $@ $(CPUOBJECTS)

%-MIC: $(MICOBJECTS)
	$(info )
	$(info Linking the MIC executable:)
	$(CXX) $(MICFLAGS) -o $@ $(MICOBJECTS)

.cc.o:
	$(info )
	$(info Compiling a CPU object file:)
	$(CXX) -c $(CPUFLAGS) $(OPTFLAGS) -o "$@" "$<"

.cc.oMIC:
	$(info )
	$(info Compiling a MIC object file:)
	$(CXX) -c $(MICFLAGS) $(OPTFLAGS) -o "$@" "$<"

run-cpu: app
	mpirun -machine machines-cpu.txt $(PWD)/app

run-mic: app-MIC
	ssh mic0 mkdir -p $(PWD)
	scp app-MIC mic0:$(PWD)/
	I_MPI_MIC=1 LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(MIC_LD_LIBRARY_PATH) mpirun -machine machines-mic.txt $(PWD)/app-MIC

run-het: app app-MIC
	ssh mic0 mkdir -p $(PWD)
	scp app-MIC mic0:$(PWD)/
	I_MPI_MIC=1 I_MPI_MIC_POSTFIX="-MIC" LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(MIC_LD_LIBRARY_PATH) mpirun -machine machines-heterogeneous.txt $(PWD)/app

instructions: 
	$(info )
	$(info TO EXECUTE THE APPLICATION: )
	$(info "make run-cpu" to run the application on the host CPU)
	$(info "make run-mic" to run the application on the coprocessor)
	$(info "make run-het" to run the application on the heterogeneous system of CPUs and MICs)
	$(info )


clean: 
	rm -f $(CPUOBJECTS) $(MICOBJECTS) $(TARGET) $(MICTARGET) *.optrpt


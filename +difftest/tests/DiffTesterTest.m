classdef (SharedTestFixtures={ ...
        matlab.unittest.fixtures.PathFixture(['..' filesep '..']),...
        matlab.unittest.fixtures.PathFixture('.'),...
        matlab.unittest.fixtures.WorkingFolderFixture...
        }) DiffTesterTest < matlab.unittest.TestCase
    %DIFFTESTERTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        systems = {'sampleModel2432', 'sampleModel2432_pp_1_1'}; % 'sampleModel2432_pp_1_1'
        
        configs = {
            {
                difftest.ExecConfig('Nrml', struct('SimulationMode', 'normal')) 
                difftest.ExecConfig('Acc', struct('SimulationMode', 'accelerator')) 
            }
            {
                difftest.ExecConfig('OptOn', struct('SimCompilerOptimization', 'on')) 
                difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
            }
        };
    end
    
    methods(TestClassSetup) % Only once for all methods
        function open_systems(testCase)
            for i=1:numel(testCase.systems)
                load_system(testCase.systems{i});
            end
        end
    end
 
    methods(TestClassTeardown)
        function close_systems(testCase)
            for i=1:numel(testCase.systems)
                bdclose(testCase.systems{i});
            end
        end
    end
    
    methods(Test)
        function testConfigBuilding(testCase)
            
            confs = {
                {
                    difftest.ExecConfig('Nrml', struct('SimulationMode', 'normal')) 
                    difftest.ExecConfig('Acc', struct('SimulationMode', 'accelerator')) 
                    difftest.ExecConfig('Rapid', struct('SimulationMode', 'rapid')) 
                }
                {
                    difftest.ExecConfig('OptOn', struct('SimCompilerOptimization', 'on')) 
                    difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
                }
            };
            
            dt = difftest.BaseTester(testCase.systems, confs);
            dt.init_exec_reports();
            
            testCase.verifyEqual(dt.exec_reports.len, 12, 'Cartesian product size incorrect');
            
            expected = load('cartesian');
            
            sysnames = cellfun(@(p)p.sys, dt.exec_reports.get_cell_T(), 'UniformOutput', false);
            testCase.verifyEqual(sysnames, expected.sysnames, 'Model names incorrect');
            
            simargs = cellfun(@(p)p.get_sim_args(), dt.exec_reports.get_cell());
            testCase.verifyEqual(simargs, expected.simargs, 'Simulation config values incorrect');
            
        end
    end
    
    methods
        
    end
end


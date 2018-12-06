classdef (SharedTestFixtures={ ...
        matlab.unittest.fixtures.PathFixture(['..' filesep '..']),...
        matlab.unittest.fixtures.PathFixture('.'),...   % To allow running test from the project directory by just adding this file's path
        matlab.unittest.fixtures.PathFixture(['3rdparty' filesep 'logging4matlab']),...
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
                fprintf('Loaded %s\n', testCase.systems{i});
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
        %% Test Cases
        function testConfigBuilding(testCase)
            %%
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
            
            dt = difftest.BaseTester(testCase.systems, testCase.get_locs(testCase.systems), confs);
            dt.init_exec_reports();
            
            testCase.verifyEqual(dt.r.executions.len, 12, 'Cartesian product size incorrect');
            
            expected = load('cartesian');
            
            sysnames = cellfun(@(p)p.sys, dt.r.executions.get_cell_T(), 'UniformOutput', false);
            testCase.verifyEqual(sysnames, expected.sysnames, 'Model names incorrect');
            
            simargs = cellfun(@(p)p.get_sim_args(), dt.r.executions.get_cell());
            testCase.verifyEqual(simargs, expected.simargs, 'Simulation config values incorrect');
            
        end
        
        function testDiffTestOnlySingleModelOptOnOff(testCase)
            %%
            models = {'sampleModel2432'};
            confs = {
                {
                    difftest.ExecConfig('OptOn', struct('SimCompilerOptimization', 'on')) 
                    difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
                }
            };
        
            dt = testCase.exec(models, confs, 2); %#ok<NASGU>
        end
        
        function testTwoModelsOptimizationOnOff(testCase)
            %%
            models = {'sampleModel2432', 'sampleModel2432_pp_1_1'};
            confs = {
                {
                    difftest.ExecConfig('OptOn', struct('SimCompilerOptimization', 'on')) 
                    difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
                }
            };
        
            dt = testCase.exec(models, confs, 4); %#ok<NASGU>
        end
        
        function testFinalValCompSingleModelOptOnOff(testCase)
            %%
%             models = {'sampleModel2432'};
%             confs = {
%                 {
%                     difftest.ExecConfig('OptOn', struct('SimCompilerOptimization', 'on')) 
%                     difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
%                 }
%             };
%             dt = testCase.exec(models, confs, 2); 
%             r = dt.r;
            loaded_data = load('cached_dt');
            r = loaded_data.r_onemodel_optonoff;
            
            cf = testCase.comparison(@difftest.FinalValueComparator, {r}); 
            
            second_exec = cf.r.oks{2};
            testCase.assertEqual(second_exec.num_signals, second_exec.num_found_signals, ...
                'All signals of first and second simulation should be found');
        end
        
        function testFinalValCompTwoModels(testCase)
            %% Not passing
%             models = {'sampleModel2432', 'sampleModel2432_pp_1_1'};
%             confs = {
%                 {
%                     difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
%                 }
%             };
%         
%             dt = testCase.exec(models, confs, 2);
            
            cached_r = load('twoModels');
            
            cf = testCase.comparison(@difftest.FinalValueComparator, {cached_r.r}); 
            
        end
    end
    
    methods
        %% Helper Methods
        function dt = exec(testCase, models, confs, num_execution)
            dt = difftest.BaseTester(models, testCase.get_locs(models), confs);
            dt.go();
            
            testCase.assertEqual(dt.r.executions.len, num_execution);
            testCase.assertTrue(dt.r.is_ok);
        end
        
        function ret = get_locs(~, models)
            cellfun(@(p)emi.open_or_load_model(p), models);
            ret = cellfun(@(p)utility.strip_last_split(get_param(p, 'FileName'), filesep), models, 'UniformOutput', false);
        end
        
        function cf = comparison(testCase, comparator, args)
            cf = comparator(args{:});
            cf.go();
            
            testCase.assertTrue(cf.r.are_oks_ok());
        end
    end
end


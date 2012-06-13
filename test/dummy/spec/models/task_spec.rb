require File.expand_path('../../spec_helper', __FILE__)

def reload_models &block
  crazy_models.reset
  crazy_models.with_helpers &block if block_given?
  crazy_models
end

describe Task do
  
  #
  # has_moderated_association
  # has_many
  #
  
  context "has_many association:" do
    before do
      reload_models.task {
        has_many :renamed_subtasks, :class_name => subtask_class_name, :foreign_key => task_fk
        has_moderated_association :renamed_subtasks
      }.subtask {
        belongs_to :task, :class_name => task_class_name, :foreign_key => task_fk
      }
    end
    
    it "creates and associates subtask (create)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks.create! :title => "Subtask 1"
    
      task = Task.first
      task.renamed_subtasks.count.should eq(0)
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "creates and associates subtask (build, save task)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks.build :title => "Subtask 1"
      task.save
    
      task = Task.first
      task.renamed_subtasks.count.should eq(0)
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "creates and associates subtask (build, save subtask)", :broken => true do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      subtask = task.renamed_subtasks.build :title => "Subtask 1"
      subtask.save
    
      task = Task.first
      task.renamed_subtasks.count.should eq(0)
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "associates (<<) existing subtask" do
      task = Task.create! :title => "Task 1"
      Subtask.create! :title => "Subtask 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks << Subtask.first

      task = Task.first
      task.renamed_subtasks.count.should eq(0)

      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)

      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "associates (push) existing subtask" do
      task = Task.create! :title => "Task 1"
      Subtask.create! :title => "Subtask 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks.push Subtask.first

      task = Task.first
      task.renamed_subtasks.count.should eq(0)

      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)

      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "moderates deleting association" do
      task = Task.create! :title => "Task 1"
      task.renamed_subtasks.create! :title => "Subtask 1"
      Moderation.last.accept
      
      Task.last.renamed_subtasks.delete(Task.last.renamed_subtasks.last)
      Task.last.renamed_subtasks.count.should eq(1)
      
      Moderation.last.accept
      Task.last.renamed_subtasks.count.should eq(0)
    end
  end
  
  #
  # has_moderated_association
  # has_many polymorphic
  #
  
  context "has_many polymorphic association:" do
    before do
      reload_models.task {
        has_many :renamed_subtasks, :class_name => subtask_class_name, :as => :parentable
        has_moderated_association :renamed_subtasks
      }.subtask {  
        belongs_to :parentable, :class_name => task_class_name, :polymorphic => true
      }
    end
    
    it "creates and associates subtask (create)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks.create! :title => "Subtask 1"
    
      task = Task.first
      task.renamed_subtasks.count.should eq(0)
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
      subtask.parentable.should eq(Task.first)
    end
  end

  #
  # has_moderated_association
  # has_one polymorphic
  #
  
  context "has_one polymorphic association:" do
    before do
      reload_models.task {
        has_one :renamed_subtask, :class_name => subtask_class_name, :as => :parentable
        has_moderated_association :renamed_subtask
      }.subtask {  
        belongs_to :parentable, :class_name => task_class_name, :polymorphic => true
      }
    end
    
    it "creates and associates subtask (create)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtask = Subtask.new :title => "Subtask 1"
      task.save
    
      task = Task.first
      task.renamed_subtask.should be_nil
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtask
      subtask.title.should eq("Subtask 1")
      subtask.parentable.should eq(Task.first)
    end
  end
  
  #
  # has_moderated_association
  # has_and_belongs_to_many
  #
  
  context "has_and_belongs_to_many association:" do
    before do
      reload_models.task {
        has_and_belongs_to_many :renamed_subtasks, :class_name => subtask_class_name, :join_table => "tasks_jointable", :foreign_key => "m1_id", :association_foreign_key => "m2_id"
        has_moderated_association :renamed_subtasks
      }.subtask {
        has_and_belongs_to_many :renamed_tasks, :class_name => task_class_name, :join_table => "tasks_jointable", :foreign_key => "m2_id", :association_foreign_key => "m1_id"
      }
    end
    
    it "creates and associates a new subtask" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks.create! :title => "Subtask 1"
      
      Subtask.count.should eq(0)
      task = Task.first
      task.renamed_subtasks.count.should eq(0)
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "associates an existing subtask" do
      task = Task.create! :title => "Task 1"
      Subtask.create! :title => "Subtask 1"
      Task.first.renamed_subtasks.count.should eq(0)
      Subtask.count.should eq(1)
      Moderation.count.should eq(0)
      task.renamed_subtasks << Subtask.first
      
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      Task.first.renamed_subtasks.count.should eq(1)
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
  end
  
  context "has_and_belongs_to_many association (create moderation):" do
    before :each do # important that we do this before EACH
      reload_models.task {
        has_moderated_create :with_associations => [:renamed_subtasks]
        has_and_belongs_to_many :renamed_subtasks, :class_name => subtask_class_name, :join_table => "tasks_jointable", :foreign_key => "m1_id", :association_foreign_key => "m2_id"
      }.subtask {
        has_and_belongs_to_many :renamed_tasks, :class_name => task_class_name, :join_table => "tasks_jointable", :foreign_key => "m2_id", :association_foreign_key => "m1_id"
      }
    end
    
    it "associates an existing subtask on create 1" do
      Task.has_moderated_association :renamed_subtasks  # important difference (had different behavior based
                                                        # on presence of this line, need to test with and without)
      Subtask.create! :title => "Subtask 1"
      Subtask.count.should eq(1)
      Moderation.count.should eq(0)
      
      task = Task.new :title => "Task 1"
      task.renamed_subtasks << Subtask.first
      task.save
      
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      Task.first.renamed_subtasks.count.should eq(1)
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "associates an existing subtask on create 2" do
      Subtask.create! :title => "Subtask 1"
      Subtask.count.should eq(1)
      Moderation.count.should eq(0)
      
      task = Task.new :title => "Task 1"
      task.renamed_subtasks << Subtask.first
      task.save
      
      Task.count.should eq(0)
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      Task.last.renamed_subtasks.count.should eq(1)
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
  end
  
  #
  # has_moderated_association
  # has_many :through
  #
  
  context "has_many :through association:" do
    before do
      reload_models.task {
        has_many :renamed_connections, :class_name => task_connection_class_name, :foreign_key => "m1_id"
        has_many :renamed_subtasks, :class_name => subtask_class_name, :through => :renamed_connections, :source => :renamed_subtask
        has_moderated_association :renamed_subtasks
        has_moderated_association :renamed_connections
      }.subtask {
        has_many :renamed_connections, :class_name => task_connection_class_name, :foreign_key => "m2_id"
        has_many :renamed_tasks, :class_name => task_class_name, :through => :renamed_connections, :source => :renamed_task
      }.task_connection {
        belongs_to :renamed_task, :class_name => task_class_name, :foreign_key => "m1_id"
        belongs_to :renamed_subtask, :class_name => subtask_class_name, :foreign_key => "m2_id"
      }
    end
    
    it "associates subtask 1 (update)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      
      conn = TaskConnection.new :title => "Connection 1"
      conn.renamed_subtask = Subtask.new :title => "Subtask 1"
      task.renamed_connections << conn
      task.save
      
      TaskConnection.count.should eq(0)
      Subtask.count.should eq(0)
    
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
      conn = Subtask.first.renamed_connections.first
      conn.title.should eq("Connection 1")
      conn.renamed_subtask.title.should eq("Subtask 1")
      conn.renamed_task.title.should eq("Task 1")
    end
    
    it "associates subtask 2 (update)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      
      task.renamed_subtasks.build :title => "Subtask 1"
      task.save
      
      TaskConnection.count.should eq(0)
      Subtask.count.should eq(0)
      Moderation.last.accept
      Moderation.count.should eq(0)
      Subtask.count.should eq(1)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "associates subtask 3 (update)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      
      task.renamed_subtasks.create! :title => "Subtask 1"
      
      TaskConnection.count.should eq(0)
      Subtask.count.should eq(0)
    
      Moderation.last.accept
      Moderation.count.should eq(0)
      Subtask.count.should eq(1)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "associates subtask 1 (create)" do
      t = Task.new :title => "Task 1"
      t.renamed_subtasks.build :title => "Subtask 1"
      t.save
      
      Subtask.count.should eq(0)
      Task.first.title.should eq("Task 1")
      Task.first.renamed_subtasks.count.should eq(0)
      Task.count.should eq(1)
      
      Moderation.last.accept

      Task.first.renamed_subtasks.count.should eq(1)
      Task.first.renamed_subtasks.first.title.should eq("Subtask 1")
    end
  end
  
  #
  # has_moderated_association
  # has_one
  #
  
  context "has_one association:" do
    before do
      reload_models.task {
        has_one :renamed_subtask, :class_name => subtask_class_name, :foreign_key => task_fk
        has_moderated_association :renamed_subtask
      }.subtask {
        belongs_to :task, :class_name => task_class_name
      }
    end
    
    it "creates and associates subtask (= new, task save)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtask = Subtask.new :title => "Subtask 1"
      task.save
    
      task = Task.first
      task.renamed_subtask.should be_nil
      Subtask.count.should eq(0)
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtask
      subtask.title.should eq("Subtask 1")
    end
    
    it "creates and associates subtask (= create, task save)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtask = Subtask.create! :title => "Subtask 1"
      task.save
    
      task = Task.first
      task.renamed_subtask.should be_nil
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtask
      subtask.title.should eq("Subtask 1")
    end
    
    it "set subtask to nil (delete)" do
      task = Task.create! :title => "Task 1"
      task.renamed_subtask = Subtask.new :title => "Subtask 1"
      task.save
      Moderation.last.accept
      
      Moderation.count.should eq(0)
      Task.first.renamed_subtask.should_not be_nil
      
      Task.first.renamed_subtask = nil
      Task.first.renamed_subtask.should_not be_nil
      
      Moderation.last.accept
      Task.first.renamed_subtask.should be_nil
    end
  end
  
  context "has_one association (create moderation):" do
    before :each do
      reload_models.task {
        has_one :renamed_subtask, :class_name => subtask_class_name, :foreign_key => task_fk
        has_moderated_create :with_associations => [:renamed_subtask]
      }.subtask {
        belongs_to :task, :class_name => task_class_name
      }
    end
    
    it "associates an existing subtask on create 1" do
      Task.has_moderated_association :renamed_subtask
      Subtask.create! :title => "Subtask 1"
      Subtask.count.should eq(1)
      Moderation.count.should eq(0)

      task = Task.new :title => "Task 1"
      task.renamed_subtask = Subtask.first
      task.save
      
      Subtask.first.task_id.should be_nil

      Task.count.should eq(0)
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      Subtask.first.task_id.should_not be_nil

      subtask = Task.first.renamed_subtask
      subtask.title.should eq("Subtask 1")
    end
    
    it "associates an existing subtask on create 2" do
      Subtask.create! :title => "Subtask 1"
      Subtask.count.should eq(1)
      Moderation.count.should eq(0)

      task = Task.new :title => "Task 1"
      task.renamed_subtask = Subtask.first
      task.save
      
      Subtask.first.task_id.should be_nil

      Task.count.should eq(0)
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      Subtask.first.task_id.should_not be_nil

      subtask = Task.first.renamed_subtask
      subtask.title.should eq("Subtask 1")
    end
  end
  
  #
  # has_moderated_create
  #
  
  context "create moderation with association:" do
    before do
      reload_models.task {
        has_many :renamed_subtasks, :class_name => subtask_class_name, :foreign_key => task_fk
        has_moderated_create :with_associations => [:renamed_subtasks]
      }.subtask {
        belongs_to :task, :class_name => task_class_name
      }
    end
    
    it "moderates create" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(1)
      Task.count.should eq(0)
      
      Moderation.last.accept
      Task.count.should eq(1)
      Task.first.title.should eq("Task 1")
    end
    
    # TODO: test all associations on create
    it "moderates assoc on create" do
      task = Task.new :title => "Task 1"
      task.renamed_subtasks.build :title => "Subtask 1"
      task.save
      Subtask.count.should eq(0)
      Moderation.last.accept
      
      Task.last.renamed_subtasks.count.should eq(1)
      Task.last.renamed_subtasks.first.title.should eq("Subtask 1")
    end
    
    it "doesn't create anything if nothing was created" do
      task = Task.create! :title => "Task 1"
      Moderation.last.accept
      
      Task.first.renamed_subtasks.count.should eq(0)
    end
  end
  
  #
  # has_moderated_destroy
  #
  
  context "destroy moderation:" do
    before do
      reload_models.task {
        has_moderated_destroy
      }
    end
    
    it "moderates destroy" do
      Task.create! :title => "Task 1"
      Task.count.should eq(1)
      Task.first.destroy
      Task.count.should eq(1)
      Moderation.last.accept
      Task.count.should eq(0)
    end
  end
  
  #
  # has_moderated_attributes
  #
  
  context "moderates attributes:" do
    before do
      reload_models.task {
        has_moderated :title
      }
    end
    
    it "moderates an attribute" do
      Task.create! :title => "Task 1", :desc => "Description"
      Task.first.title.should be_blank
      Task.first.desc.should eq("Description")
      Moderation.last.accept
      Task.first.title.should eq("Task 1")
      Task.first.update_attribute(:title, "Task 2")
      Task.first.title.should eq("Task 1")
      Moderation.last.accept
      Task.first.title.should eq("Task 2")
    end
  end
  
  #
  # other features
  #
  
  context "common features:" do
    it "get_moderation_attributes can be overriden in model" do
      reload_models.task {
        has_moderated_create
        self.class_eval do
          def get_moderation_attributes
            { :test => "ok" }
          end
        end
      }
      Task.create! :title => "Task 1"
      data = YAML::load(Moderation.last.data)[:create][:attributes]
      data.should_not be_blank
      data[:test].should_not be_blank
      data[:test].should eq("ok")
      data.keys.count.should eq(1)
    end
    
    it "knows if it's a create moderation" do
      reload_models.task {
        has_moderated_create
      }
      
      Task.create! :title => "Task 1"
      
      Moderation.last.create?.should be_true
      Moderation.last.destroy?.should be_false
      Moderation.last.update?.should be_false
    end
    
    it "knows if it's a destroy moderation" do
      reload_models.task {
        has_moderated_destroy
      }
      
      Task.create! :title => "Task 1"
      Task.last.destroy
      
      Moderation.last.destroy?.should be_true
      Moderation.last.create?.should be_false
      Moderation.last.update?.should be_false
    end
    
    it "calls moderation callbacks on destroy" do
      reload_models.task {
        has_moderated_create
        def self.moderatable_discard(m)
          raise "moderatable_discard"
        end
      }
      Task.create!
      expect { Moderation.last.destroy }.should raise_error("moderatable_discard")
    end
  end
  
  context "hooks:" do
    before do
      reload_models.task {
        has_moderated :title
        moderation_creating do |moderation|
          moderation.data = "Test!"
        end
      }
    end
    
    it "handles a creating hook properly" do
      Task.create! :title => "Task 1"
      Moderation.count.should eq(1)
      Moderation.last.data.should eq("Test!")
    end
  end
  
  context "preview:" do
    it "shows a live preview of changed attributes" do
      reload_models.task {
        has_moderated :title
      }
      
      Task.create! :title => "Task 1"
      Task.last.title.should be_blank
      
      last_task_id = Task.last.id
      Moderation.last.live_preview do |preview|
        preview.title.should eq("Task 1")
        preview.id.should eq(last_task_id)
      end
      
      Task.last.title.should be_blank
    end
    
    it "shows a saved preview of changed attributes" do
      reload_models.task {
        has_moderated :title
      }
      
      task = Task.create! :title => "Task 1"
      Task.last.title.should be_blank
      
      preview = Moderation.last.preview
      preview.title.should eq("Task 1")
      preview.id.should eq(Task.last.id)
      Task.last.title.should be_blank
    end
    
    it "supports dirty tracking for the saved preview" do
      reload_models.task {
        has_moderated :title
      }
      
      task = Task.create! :title => "Task 1"
      Task.last.title.should be_blank
      
      preview = Moderation.last.preview
      preview.title_changed?.should be_true
      preview.title_change.should eq([nil, "Task 1"])
    end
    
    it "supports updating moderation attributes for the saved preview if :saveable => true" do
      reload_models.task {
        has_moderated :title
      }
      
      task = Task.create! :title => "Task 1"
      Task.last.title.should be_blank
      
      preview = Moderation.last.preview(:saveable => true)
      preview.title = "Task 2"
      preview.update_moderation
      
      moderation = Moderation.last
      moderation.parsed_data.should eq({:attributes=>{"title"=>"Task 2"}})
      moderation.accept
      Task.last.title.should eq("Task 2")
    end
    
    it "doesn't support updating moderation attributes for the saved preview by default" do
      reload_models.task {
        has_moderated :title
      }
      
      task = Task.create! :title => "Task 1"
      Task.last.title.should be_blank
      
      moderation = Moderation.last
      preview = Moderation.last.preview
      preview.frozen?.should be_true
      expect { preview.title = "Task 2" }.should raise_error
      expect { preview.update_moderation }.should raise_error
      
      moderation = Moderation.last
      moderation.accept
      Task.last.title.should eq("Task 1")
    end
    
    it "shows a saved preview of has_many association" do
      reload_models.task {
        has_many :renamed_subtasks, :class_name => subtask_class_name, :foreign_key => task_fk
        has_moderated_association :renamed_subtasks
      }.subtask {
        belongs_to :task, :class_name => task_class_name
      }
      
      task = Task.create! :title => "Task 1"
      
      task.renamed_subtasks.create! :title => "Subtask 1"
      preview = Moderation.last.preview
      subtask = preview.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
      subtask.id.should_not be_blank
      subtask.task.should_not be_blank
      
      Task.last.renamed_subtasks.count.should eq(0)
      Subtask.count.should eq(0)
    end
    
    it "shows a saved preview of has_many :through association" do
      reload_models.task {
        attr_accessible :title, :desc
        has_many :renamed_connections, :class_name => task_connection_class_name, :foreign_key => "m1_id"
        has_many :renamed_subtasks, :class_name => subtask_class_name, :through => :renamed_connections, :source => :renamed_subtask
        has_moderated_association :renamed_subtasks
        has_moderated_association :renamed_connections
      }.subtask {
        attr_accessible :title, :desc
        belongs_to :task
        has_many :renamed_connections, :class_name => task_connection_class_name, :foreign_key => "m2_id"
        has_many :renamed_tasks, :class_name => task_class_name, :through => :renamed_connections, :source => :renamed_task
      }.task_connection {
        belongs_to :renamed_task, :class_name => task_class_name, :foreign_key => "m1_id"
        belongs_to :renamed_subtask, :class_name => subtask_class_name, :foreign_key => "m2_id"
      }

      task = Task.create! :title => "Task 1"
      conn = TaskConnection.new :title => "Connection 1"
      conn.renamed_subtask = Subtask.new :title => "Subtask 1"
      task.renamed_connections << conn
      task.save
      
      TaskConnection.count.should eq(0)
      Subtask.count.should eq(0)
      
      task = Moderation.last.preview
      
      TaskConnection.count.should eq(0)
      Subtask.count.should eq(0)
      Moderation.count.should eq(1)
      
      subtask = task.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
      subtask.renamed_connections.first.should be_present
      conn = task.renamed_connections.first
      conn.title.should eq("Connection 1")
      conn.renamed_subtask.title.should eq("Subtask 1")
      conn.renamed_task.title.should eq("Task 1")
      
      # everything has to be frozen
      task.frozen?.should be_true
      task.renamed_subtasks.frozen?.should be_true
      task.renamed_connections.frozen?.should be_true
      subtask.frozen?.should be_true
      subtask.renamed_connections.frozen?.should be_true
      conn.frozen?.should be_true
      conn.renamed_task.frozen?.should be_true
      conn.renamed_subtask.frozen?.should be_true
    end
  end
end
